import System.IO
import qualified Data.ByteString.Lazy as B
import Data.Binary
import Data.Binary.Get
import Data.Binary.Put
--import Data.Bits
import Data.Int

main :: IO ()
main = do
    inh <- openBinaryFile "test.gba" ReadMode
    outh <- openBinaryFile "dump.gba" WriteMode
    doStuff inh outh
    hClose inh
    hClose outh
    
doStuff :: Handle -> Handle -> IO ()
doStuff inh outh = do
    hSeek inh AbsoluteSeek offset
    bs <- B.hGetContents inh
    --B.hPut outh $ runPut (putFontChar (runGet getFontChar bs))
    B.hPut outh $ runPut (putFontChars (runGet (getFontChars 0x1FFF) bs))
  where char = 0--0x00DC
        offset = 0x938264 + (char * 0x18) -- 0x18 = [9380AC+8]

getTile = do
    pack <- getWord32le
    return (regs pack)
  where
    mask x shift = 0x11111111 .&. x `shiftR` shift
    regs x = mask x 0 : mask x 1 : mask x 2 : mask x 3 : [] --(mask x 0, mask x 1, mask x 2, mask x 3)
    
getFontChar = do
    topLeft <- getTile
    topRight <- getTile
    midLeft <- getTile
    midRight <- getTile
    btmLeft <- getTile
    btmRight <- getTile
    return (topLeft, topRight, midLeft, midRight, btmLeft, btmRight)
--  where blank = [0,0,0,0] :: [Word32]

--getFontChars :: Int -> Get [([Word32], [Word32], [Word32], [Word32], [Word32], [Word32])]
getFontChars 0 = return []
getFontChars x = do
	a <- getFontChar
	xs <- getFontChars (x-1)
	return (a : xs)
  
putFontChars [] = return ()
putFontChars (x:xs) = do
	putFontChar x
	putFontChars xs
  
putFontChar (b1, b2, c1, c2, d1, d2) = do
    putTile blank
    putTile b1      -- top left tile complete
    putTile blank
    putTile b2      -- top right tile complete
    putTile c1
    putTile d1
    putTile c2
    putTile d2
  where blank = [0,0,0,0] :: [Word32]

putTile (x:xs) = do 
    putWord32le x
    putTile xs
putTile [] = return ()


-- chars loaded in chunks of 4 lines, 1st chunk is bottom half of first tile, 2 and 3 are top and bottom of 2nd tile
-- main unpack called twice because 2 tiles wide

-- skips down 0x10 at the beginning (4 words)
-- stores 4 unpacked words, skips 0x20 (to get to bottom chunk of next tile over)