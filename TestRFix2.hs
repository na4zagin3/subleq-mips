{-# LANGUAGE FlexibleInstances, FlexibleContexts, MultiParamTypeClasses, UndecidableInstances, TemplateHaskell, OverloadedStrings #-}
module Main where

import Language.Subleq.Model.Prim
import Language.Subleq.Model.Memory as Mem
import Language.Subleq.Model.Architecture.IntMachine
-- import qualified Language.Subleq.Model.InstructionSet.Subleq as Subleq
import qualified Language.Subleq.Model.InstructionSet.SubleqR as Subleq
import qualified Language.Subleq.Assembly as A
import qualified Language.Subleq.Assembly.Export.Elf2Mem as A
import Text.Parsec
import Control.Applicative
import Text.PrettyPrint hiding ((<+>))
import qualified Text.PrettyPrint as PP
import qualified Data.ByteString as B
-- import Data.Maybe
import Data.Map (Map)
import qualified Data.Map as M
import Data.Set (Set)
import qualified Data.Set as S
import Data.FileEmbed
import Control.Monad
-- import Control.Monad.State
-- import Control.Lens
import Control.Arrow
import Test.QuickCheck
-- import Test.QuickCheck.Text
-- import Test.QuickCheck.All
import Data.Word
import Data.Int
import Data.Bits
import Data.Function
import Text.Printf

import qualified Data.ByteString.Lazy as BL
import qualified Data.Random as R
import qualified Data.Random.Distribution.Exponential as R
import qualified Data.Random.Distribution.Uniform as R

import qualified Data.Csv as CSV

import qualified SubleqTestUtils as T

type SubleqWord = Int32
type SubleqUWord = Word32
wordLength :: (Integral a, Num a) => a
wordLength = 32

{-
type SubleqWord = Int16
type SubleqUWord = Word16
wordLength :: (Integral a, Num a) => a
wordLength = 16
-}


type Fix2SubleqMemory = M.Map SubleqWord SubleqWord
type Fix2SubleqState = SubleqState SubleqWord SubleqWord Fix2SubleqMemory

locateArg :: A.LocateArg
locateArg xs = M.fromList $ zip xs [0..3]

subleqRoutines :: B.ByteString
subleqRoutines = $(embedFile "subleqr-int-fix2.sq")

subleqModule :: A.Module
subleqModule = either (error . show) A.expandMacroAll $ parse A.parseModule "parserModule" subleqRoutines

inc, dec :: SubleqWord
inc = 0x4
dec = 0x5

subleqMA :: A.MemoryArchitecture (M.Map SubleqWord SubleqWord)
subleqMA = A.MemoryArchitecture { A.instructionLength = 3
                                , A.wordLength = 1
                                , A.locateArg = locateArg
                                , A.locateStatic = M.fromList [ ("End", 0)
                                                              , ("Inc", 0x4)
                                                              , ("Dec", 0x5)
                                                              , ("Z",   0x6)
                                                              , ("T0",  0x8)
                                                              , ("T1",  0x9)
                                                              , ("T2",  0xa)
                                                              , ("T3",  0xb)
                                                              , ("T4",  0xc)
                                                              , ("T5",  0xd)
                                                              , ("T6",  0xe)
                                                              -- , ("Min",  0x0d)
                                                              -- , ("Max",  0x0e)
                                                              , ("CW",  0xf)
                                                              , ("Min",  0x10)
                                                              , ("Max",  0x11)
                                                              ]
                                , A.writeWord = Mem.write `on` fromIntegral
                                }

subleqMAInitialMem :: M.Map SubleqWord SubleqWord
subleqMAInitialMem =  Mem.write 0x11 maxBound . Mem.write 0x10 minBound . Mem.write 0xf wordLength . Mem.write inc (-1) . Mem.write dec 1 $ M.empty
-- subleqMAInitialMem =  Mem.write 0x0e maxBound . Mem.write 0x0d minBound . Mem.write 0xf wordLength . Mem.write inc (-1) . Mem.write dec 1 $ M.empty
{-
subleqMAInitialMem =  foldr (<$) M.empty [ Mem.write 0xf wordLength
                                         , Mem.write inc (-1)
                                         , Mem.write dec 1
                                         ]
-}
subleqMATextSection :: Integer
subleqMATextSection = 0x100

executeSubroutineWithStates :: A.Id -> [SubleqWord] -> Maybe Integer -> Maybe (Maybe ([SubleqWord], Fix2SubleqState), [Fix2SubleqState])
executeSubroutineWithStates x args mn = T.executeSubroutineWithStates Subleq.step pos mem x args mn
    where
      (pos, mem) = T.assembleMachine subleqMA subleqMATextSection subleqModule subleqMAInitialMem

maximumTry :: Maybe Integer
-- maximumTry = Just 1000000
maximumTry = Just 10000

executeSubroutineWithModification :: A.Id -> [SubleqWord] -> ([SubleqWord], Set SubleqWord)
executeSubroutineWithModification x args = case executeSubroutineWithStates x args maximumTry of
                             Just (Just (res, end), init:_) ->  (res, changedAddresses end init)
                             Just (Nothing, _) -> error "Not terminated"
                             Nothing -> error "Not found"

executeSubroutine :: A.Id -> [SubleqWord] -> [SubleqWord] 
executeSubroutine x args = if diffs `S.isSubsetOf` S.fromList [0..(fromIntegral $ length args - 1)] then res else error $ "it corrupses: " ++ show diffs
    where
      (res, diffs) = executeSubroutineWithModification x args

prop_IntWordTrip :: Int8 -> Bool
prop_IntWordTrip a = a == fromIntegral w
    where
      w :: Word8
      w = fromIntegral a

prop_WordIntTrip :: Word8 -> Bool
prop_WordIntTrip a = a == fromIntegral w
    where
      w :: Int8
      w = fromIntegral a

prop_Add :: SubleqWord -> SubleqWord -> SubleqWord -> Bool
prop_Add a b c = [b + c, b, c] == executeSubroutine "addu" [a, b, c]

prop_Sub :: SubleqWord -> SubleqWord -> SubleqWord -> Bool
prop_Sub a b c = [b - c, b, c] == executeSubroutine "subu" [a, b, c]

prop_Mflo :: SubleqWord -> SubleqWord -> Bool
prop_Mflo a lo = [lo, lo] == executeSubroutine "mflo" [a, lo]

prop_Mtlo :: SubleqWord -> SubleqWord -> Bool
prop_Mtlo lo a = [a, a] == executeSubroutine "mtlo" [lo, a]

-- prop_Mult :: SubleqWord -> SubleqWord -> SubleqWord -> Bool
-- prop_Mult a b c = [b * c, b, c] == executeSubroutine "mult" [a, b, c]

prop_JezoTest :: SubleqUWord -> Bool
prop_JezoTest a  = fromIntegral a' == f a
    where
      [a'] = executeSubroutine "jezoTest" $ map fromIntegral [a]
      f 0 = 0
      f x | even x = 1
          | odd  x = -1

-- prop_MultuLo :: SubleqUWord -> SubleqUWord -> Bool
-- prop_MultuLo b c  = fromIntegral a' == b * c
--     where
--       [a', _, _] = executeSubroutine "multuLo" $ map fromIntegral [0, b, c]
-- 
-- prop_Floor2pow :: NonNegative SubleqWord -> NonNegative SubleqWord -> NonNegative SubleqWord -> Bool
-- prop_Floor2pow (NonNegative a) (NonNegative b) (NonNegative c)  = a' == a && r1 <= a && (a == 0 || a < 2 * r1) && r2 == a `div` 2
--     where
--       [r1, r2, a'] = executeSubroutine "floor2pow" [b, c, a]

prop_Bne :: SubleqWord -> SubleqWord -> SubleqWord -> SubleqWord -> Bool
prop_Bne rs rt off pc  = [rs', rt', off'] == [rs, rt, off] && ((rs == rt && pc' == pc + off) || (rs /= rt && pc' == pc))
    where
      [rs', rt', off', pc'] = executeSubroutine "bne" [rs, rt, off, pc]

prop_BneA :: SubleqWord -> SubleqWord -> SubleqWord -> Bool
prop_BneA rs off pc  = [rs', off'] == [rs, off] && pc' == pc + off
    where
      [rs', off', pc'] = executeSubroutine "bnea" [rs, off, pc]

prop_Sll :: SubleqUWord -> SubleqUWord -> SubleqUWord -> Bool
prop_Sll rd rt sa  = [rt', s'] == [rt, s] && rd' == rt `shift` fromIntegral s
    where
      s = sa `mod` wordLength
      [rd', rt', s'] = map fromIntegral $ executeSubroutine "sll" $ map fromIntegral [rd, rt, s]

prop_Srl :: SubleqUWord -> SubleqUWord -> SubleqUWord -> Bool
prop_Srl rd rt sa  = [rt', s'] == [rt, s] && rd' == rt `shift` (-(fromIntegral s))
    where
      s = sa `mod` wordLength
      [rd', rt', s'] = map fromIntegral $ executeSubroutine "srl" $ map fromIntegral [rd, rt, s]

prop_Srl1Test :: SubleqUWord -> SubleqUWord -> Bool
prop_Srl1Test rd rs  = rs' == rs && rd' == rs `shift` (-1)
    where
      [rd', rs'] = map fromIntegral $ executeSubroutine "srl1Test" $ map fromIntegral [rd, rs]

prop_Srl1dTest :: SubleqUWord -> SubleqUWord -> Bool
prop_Srl1dTest rh rl  = rl' == rl `shift` 1 && rh' == (rh `shift` 1) + s
    where
      s = rl `shift` (1 - wordLength)
      [rh', rl'] = map fromIntegral $ executeSubroutine "srl1dTest" $ map fromIntegral [rh, rl]

prop_Srl1dcTest :: SubleqUWord -> SubleqUWord -> SubleqUWord -> Bool
prop_Srl1dcTest rd rh rl  = rd' == s && rl' == rl `shift` 1 && rh' == (rh `shift` 1) + s
    where
      s = rl `shift` (1 - wordLength)
      [rd', rh', rl'] = map fromIntegral $ executeSubroutine "srl1dcTest" $ map fromIntegral [rd, rh, rl]

srl1dTestCd :: SubleqUWord -> SubleqUWord -> SubleqUWord -> (SubleqUWord, SubleqUWord, SubleqUWord)
srl1dTestCd rd rh rl  = (s, (rh `shift` 1) + s, rl `shift` 1)
    where
      s = rl `shift` (1 - wordLength)

prop_Sra :: SubleqWord -> SubleqWord -> SubleqWord -> Bool
prop_Sra rd rt sa  = [rt', s'] == [rt, s] && rd' == rt `shift` (-(fromIntegral s))
    where
      s = sa `mod` wordLength
      [rd', rt', s'] = map fromIntegral $ executeSubroutine "sra" $ map fromIntegral [rd, rt, s]

prop_Multu :: SubleqUWord -> SubleqUWord -> SubleqUWord -> SubleqUWord -> Bool
prop_Multu hi lo rs rt  = rs' == rs && rt' == rt && (iHi `shift` wordLength) + iLo == iRs * iRt
    where
      iHi, iLo, iRs, iRt :: Integer
      [iHi, iLo, iRs, iRt] = map fromIntegral [hi', lo', rs', rt']
      [hi', lo', rs', rt'] = map fromIntegral $ executeSubroutine "multu" $ map fromIntegral [hi, lo, rs, rt]

prop_MultD :: SubleqWord -> SubleqWord -> SubleqWord -> SubleqWord -> Bool
prop_MultD hi lo rs rt  = (iHi `shift` wordLength) + iLo == iRs * iRt
    where
      iHi, iLo, iRs, iRt :: Integer
      iLo = fromIntegral (fromIntegral lo' :: SubleqUWord)
      [iHi, iRs, iRt] = map fromIntegral [hi', rs, rt]
      [hi', lo', _, _] = executeSubroutine "multD" [hi, lo, rs, rt]

prop_Mult :: SubleqWord -> SubleqWord -> SubleqWord -> SubleqWord -> Bool
prop_Mult hi lo rs rt  = [rs', rt'] == [rs, rt] && (iHi `shift` wordLength) + iLo == iRs * iRt
    where
      iHi, iLo, iRs, iRt :: Integer
      iLo = fromIntegral (fromIntegral lo' :: SubleqUWord)
      [iHi, iRs, iRt] = map fromIntegral [hi', rs, rt]
      [hi', lo', rs', rt'] = executeSubroutine "mult" [hi, lo, rs, rt]

prop_Slt :: SubleqWord -> SubleqWord -> SubleqWord -> Bool
prop_Slt rd rs rt  = [rd', rs', rt'] == [if rs < rt then 1 else 0, rs, rt]
    where
      [rd', rs', rt'] = executeSubroutine "slt"  [rd, rs, rt]

prop_Sltu :: SubleqUWord -> SubleqUWord -> SubleqUWord -> Bool
prop_Sltu rd rs rt  = [rd', rs', rt'] == [if rs < rt then 1 else 0, rs, rt]
    where
      [rd', rs', rt'] = map fromIntegral $ executeSubroutine "sltu" $ map fromIntegral [rd, rs, rt]

multD hi lo rs rt  = ([(iHi `shift` wordLength) + iLo, iHi `shift` wordLength, iHi, iLo, iRs, iRt], (iHi `shift` wordLength) + iLo == iRs * iRt)
    where
      iHi, iLo, iRs, iRt :: Integer
      iLo = fromIntegral (fromIntegral lo' :: SubleqUWord)
      [iHi, iRs, iRt] = map fromIntegral [hi', rs, rt]
      [hi', lo', _, _] = executeSubroutine "multD" [hi, lo, rs, rt]

showFix2SubleqState :: Fix2SubleqState -> Doc
showFix2SubleqState (pc, mem) = integer (fromIntegral pc) <> colon PP.<+> hsep (map (\a-> integer $ memread a mem) [0..15]) PP.<+> colon PP.<+> hsep (map (\a-> integer $ memread a mem) [16..31]) PP.<+> colon PP.<+> integer (memread 0x120 mem) PP.<+> colon PP.<+>  hsep (map (\a-> integer $ memread a mem) [pc..(pc+2)])
    where
      memread a mem = fromIntegral $ Mem.read (fromIntegral a) mem

type SubleqResult a w m = Maybe (Maybe ([w], SubleqState a w m), [SubleqState a w m])
type Fix2SubleqResult = SubleqResult SubleqWord SubleqWord Fix2SubleqMemory

printExecution :: Fix2SubleqResult -> Doc
printExecution Nothing = text "Subroutine not found"
printExecution (Just (Nothing, ss)) = text "Non terminated" $$ vcat (take 50 $ map showFix2SubleqState ss)
printExecution r@(Just (Just (args, end), ss)) = status $$ history $$ result $$ insns $$ memoryDiff
    where
      status = text "Terminated"
      history = vcat (map showFix2SubleqState ss)
      result = text "result: " <> text (show args) <> semi PP.<+> hsep (map (text . printf "%x") args)
      insns = text "instructions: " <> integer (T.measureInsns r)
      memoryDiff = text "modified: " <> text (show $ changedAddresses end $ head ss)


changedAddresses :: Fix2SubleqState -> Fix2SubleqState -> Set SubleqWord
changedAddresses (_, mem) (_,init) = M.foldrWithKey (\k v a-> if v then S.insert k a else a) S.empty  $ M.mergeWithKey f g g mem init -- M.mergeWithKey (/=) mem init
    where
      f :: SubleqWord -> SubleqWord -> SubleqWord -> Maybe Bool
      f _ m1 m2 | m1 == m2 = Nothing
                | otherwise = Just True
      g ::  Map SubleqWord SubleqWord -> Map SubleqWord Bool
      g = M.map (const True) . M.filter (/= 0)

printModule = putStrLn $ render $ A.printModule subleqModule

printSubroutine s addr = f loc
    where
      obj = A.lookupModule s subleqModule
      loc = obj >>= A.locate subleqMA addr
      f (Just (o, _)) = putStrLn $ render $ A.printObject o
      f _ = putStrLn "not found"

debugSubroutine :: A.Id -> [SubleqWord] -> Maybe Integer -> Doc
debugSubroutine i args tries = printExecution $ executeSubroutineWithStates i args tries

return []

randomSize :: (R.Distribution R.Uniform a, Num a) => R.RVar a
randomSize = R.uniform 0 (fromIntegral wordLength)

res :: Int -> IO [Double]
-- res :: (Distribution Uniform b, MonadRandom f, Functor f, Floating b) => Int -> f [b]
res n = map (2 **) <$> ( replicateM n . R.sample $ randomSize)

measureMultu n = do
    xs <- map floor <$> res n
    ys <- map floor <$> res n
    let xys = zip xs ys
    return $ do (x, y) <- xys
                let res = T.measureInsns $ executeSubroutineWithStates "multu" [0,0,x,y] maximumTry
                let ux = fromIntegral x :: SubleqUWord
                let uy = fromIntegral y :: SubleqUWord
                let pux = logBase 2 $ fromIntegral ux :: Double
                let puy = logBase 2 $ fromIntegral uy :: Double
                return (ux, uy, pux, puy, res)

measureSra n = do
    xs <- map floor <$> res n
    ys <- replicateM n $ R.sample randomSize
    let xys = zip xs ys
    return $ do (x, y) <- xys
                let res = T.measureInsns $ executeSubroutineWithStates "sra" [0,x,y] maximumTry
                return (x, y, res)

measureSrl n = do
    xs <- map floor <$> res n
    ys <- replicateM n $ R.sample randomSize
    let xys = zip xs ys
    return $ do (x, y) <- xys
                let res = T.measureInsns $ executeSubroutineWithStates "srl" [0,x,y] maximumTry
                return (x, y, res)

outputCsv :: CSV.ToRecord a => FilePath -> [BL.ByteString] -> [a] -> IO ()
outputCsv path header f = BL.writeFile path =<< (return $ BL.concat [BL.intercalate "," header, "\n", CSV.encode f])

showModule = A.renderLoadPackResult $ A.loadModulePacked subleqMA subleqMATextSection subleqModule subleqMAInitialMem

main :: IO ()
main = do
    ok <- $quickCheckAll
    if ok
      then do
        let n = 10000
        putStrLn "Measure multu"
        outputCsv "measure-subleqr-multu.csv" ["arg1","arg2","parg1","parg2","insns"] =<< measureMultu n
        putStrLn "Measure sra"
        outputCsv "measure-subleqr-sra.csv" ["arg1","arg2","insns"] =<< measureSra n
        putStrLn "Measure srl"
        outputCsv "measure-subleqr-srl.csv" ["arg1","arg2","insns"] =<< measureSrl n
      else putStrLn "Verification Failed!"