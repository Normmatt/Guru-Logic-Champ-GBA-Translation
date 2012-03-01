-- Font Dumper for Guru Logic Champ cutscenes
-- code by Spikeman, created 2/29/2012

import System.IO
import qualified Data.ByteString.Lazy as B
import Data.Binary
import Data.Binary.Get as G
import Data.Binary.Put
import Data.Bits
import Numeric
import Data.List

ptrTableAddr = 0x2F0A44
fileOut = "test data/test.gba" --"../../rom/input.gba"
fileIn = "../../gfx/cutscene_font_eng.gba"

--hex :: B.ByteString -> String
hex bs = '0':'x':(intercalate ", 0x" $ map (\x -> showHex x "") $ B.unpack bs)

main = do
    inh <- openBinaryFile fileIn ReadMode
    outh <- openBinaryFile fileOut WriteMode
    processFiles inh outh
    hClose inh
    hClose outh
	
processFiles inh outh = do
	bs <- B.hGetContents inh
	B.hPut outh $ runPut $ putRLData $ runGet (rlCompress B.empty) (runGet getFontChar bs)
	putStrLn "Done."
		
rlCompress bs = do
	empty <- isEmpty	
	if empty
		then return bs
		else do
			chunk <- getChunk
			rlCompress (B.append bs chunk)
	
getChunk = do
	try <- lookAhead $ tryGet3
	if try
		then do
			x <- getWord8
			count <- getWhileEqual 0 x
			return $ B.pack [(count - 2) .|. 0x80, x] -- generate compressed data (0x80 is flag bit)
		else do -- copy, dont compress
			(count, bs) <- getWhileNotEqual 0 (B.empty)
			return $ B.cons (count) bs
	
getWhileEqual count x = do
	empty <- isEmpty	-- note: empty checking should be in a monad?
	if empty
		then return count
		else do
			y <- lookAhead $ getWord8
			if (x == y)
				then do
					getWord8
					getWhileEqual (count+1) x
				else return count
		
getWhileNotEqual count bs = do
	empty <- isEmpty
	if empty
		then return (count, bs) -- not sure if this is correct
		else do
			y <- getWord8
			try <- lookAhead $ tryGet2 y
			if not try
				then do
					try2 <- lookAhead $ tryGet3
					if try2
						then return (count, B.snoc bs y)
						else getWhileNotEqual (count+1) (B.snoc bs y)
				else return (count, B.snoc bs y)
		
tryGet2 x = do
	a <- getWord8
	b <- getWord8
	return (a == x && b == x)
	
tryGet3 = do
	x <- getWord8
	tryGet2 x
	
getFontChar = do
	getLazyByteString 0x80	-- size of a character
	
putHeader = do
	putWord8	0x30	-- bit 0-3 = 0 - reserved, bit 4-7 = 3 - RL compression
	putWord8	0x80	-- decompressed size
	putWord8	0
	putWord8	0		-- this is 0x000080 in little endian, because there's no putWord24le
	
putRLData bs = do
	putHeader
	putLazyByteString bs