-- Font Dumper for Guru Logic Champ cutscenes
-- code by Spikeman, based on Rhythm Tengoku font dumper

-- Font is RL compressed, and decompressed by RLUncompVram BIOS function
-- possible font values range from 0x00-FF, pointer table to compressed data at 0x082F0A44

import System.IO
import qualified Data.ByteString.Lazy as B
import Data.Binary
import Data.Binary.Get as G
import Data.Binary.Put
import Data.Bits
import Numeric -- for showHex

ptrTableAddr = 0x2F0A44
fileIn = "test data/input.gba"
fileOut = "test data/test_dump.gba"

main :: IO ()
main = do
    inh <- openBinaryFile fileIn ReadMode
    outh <- openBinaryFile fileOut WriteMode
    processFiles inh outh
    hClose inh
    hClose outh
    
processFiles :: Handle -> Handle -> IO ()
processFiles inh outh = do
	addr <- getAddr 1 inh
	hSeek inh AbsoluteSeek (fromIntegral $ addr .&. 0xFFFFFF)
	bs <- B.hGetContents inh
	B.hPut outh $ runPut (putLazyByteString (runGet doRLUncomp bs))
	
getAddr char h = do
	hSeek h AbsoluteSeek (ptrTableAddr + (char * 4))
	bs <- B.hGet h 4			-- read pointer into bytestring
	return $ runGet (getWord32le) bs
	
doRLUncomp = do
	(_, comp_type, decomp_size) <- getHeader
	-- error if comp_type != 0x03
	bs <- getAllChunks (fromIntegral decomp_size) B.empty
	return bs
		
getHeader = do
	flags <- getWord8
	let reserved = flags .&. 0xF				-- reserved (not used)
	let comp_type = shiftR (flags .&. 0xF0) 4	-- compression type, should be 0x03 for RL compression
	decomp_size <- getWord24le					-- size of decompressed data
	return $ (reserved, comp_type, decomp_size)
  where
	getWord24le = do	-- get a 24 bit little-endian integer
		b1 <- getWord8
		b2 <- getWord8
		b3 <- getWord8
		return $ (shiftL b3 16) .|. (shiftL b2 8) .|. b1
		
getChunk = do
	ctrl <- getWord8
	getChunk_ ctrl ((ctrl .&. 0x80) == 0x80) -- if bit 7 = 1, incoming data is compressed, else decompressed
  where
	--getChunk_ :: Word8 -> Bool -> Get B.ByteString
	getChunk_ ctrl True = do
		b <- getWord8
		let count = fromIntegral $ (ctrl .&. 0x7F) + 3
		return (B.take count (B.repeat b)) -- return count copies of the read byte (eg. 82 00 -> 00 00 00 00 00)
	getChunk_ ctrl False = do
		let count = fromIntegral $ (ctrl .&. 0x7F) + 1
		getLazyByteString count
		
getAllChunks len bs = do
	--empty <- isEmpty
	--if empty
	if (B.length bs) == len
		then return bs
		else do
			chunk <- getChunk
			getAllChunks len (B.append bs chunk)
