-- Font Dumper for Guru Logic Champ cutscenes
-- code by Spikeman, created 2/29/2012
module Main where

import System.IO
import qualified Data.ByteString.Lazy as B
import Data.Binary
import Data.Binary.Get as G
import Data.Binary.Put
import Data.Bits
import Numeric
import Data.List
import System (getArgs)
import Control.Monad (when)

gfxStartAddr = 0x2EACC4
ptrTableAddr = 0x2F0A44
--fileOut = "../../rom/output.gba"
--fileIn = "../../gfx/cutscene_font_eng.gba"
debug = False

--hex :: B.ByteString -> String
hex bs = '0':'x':(intercalate ", 0x" $ map (\x -> showHex x "") $ B.unpack bs)

main = do
	args <- getArgs
	if (length args) /= 2
		then putStrLn "Usage: font_insert font_graphics.bin output_rom.gba"
		else do
			let fileIn = head args
			let fileOut = head . tail $ args -- get second argument
			inh <- openBinaryFile fileIn ReadMode
			outh <- openBinaryFile fileOut ReadWriteMode --WriteMode deletes file before writing
			processFiles inh outh
			hClose inh
			hClose outh
	
processFiles inh outh = do
	bs <- B.hGetContents inh
	insertFont 0 bs gfxStartAddr
	putStrLn "Done."
  where
	insertFont 0x100 _ _ = return () -- dumped all characters, so return
	insertFont x bs ptr = do
		hSeek outh AbsoluteSeek (tblAddr x)
		B.hPut outh $ runPut $ putPointer ptr	-- write pointer
		hSeek outh AbsoluteSeek (fromIntegral ptr)
		let (char, nextbs, _) = runGetState getFontChar bs 0
		let rldata = runGet (rlCompress B.empty) char
		
		size <- putAndGetSize rldata
		
		when debug $ do
			putStr $ showString "Wrote char " $ hex (B.pack [(fromIntegral x)])
			putStr $ showString " at " $ showHex ptr ""
			putStrLn $ showString "  size: " $ hex (B.pack [(fromIntegral $ adjustSize size)])
		
		--insertFont 0x100 bs ptr
		insertFont (x+1) nextbs (ptr + (fromIntegral $ adjustSize size)) 
	tblAddr x = ptrTableAddr + (x * 4)
	adjustSize x = x + (4 - mod x 4) + 4 -- adjust size for 4 byte alignment, and add 4 bytes for header
	putAndGetSize bs = do
		B.hPut outh $ runPut $ putRLData bs	-- write compressed character
		return $ B.length bs
		
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
	
putPointer addr = do
	putWord32le (addr .|. 0x08000000)
	
putHeader = do
	putWord8	0x30	-- bit 0-3 = 0 - reserved, bit 4-7 = 3 - RL compression
	putWord8	0x80	-- decompressed size
	putWord8	0
	putWord8	0		-- this is 0x000080 in little endian, because there's no putWord24le
	
putRLData bs = do
	putHeader
	putLazyByteString $ pad bs -- make sure data is 4 byte aligned
	
-- for aligning data to 4 bytes
pad bs | len > 0 = B.append bs $ B.replicate (4 - len) 0x00
  where len = (mod . B.length) bs 4
pad bs = bs