module Stream where

import Control.Applicative (Alternative (..))
import Control.Monad (liftM, ap)

import qualified Source
import qualified Iterator ( Iterator(..) )


data ProcessResult itrT va
  = Processed va itrT
  | OptionFailed itrT
  | ProcessFailed String itrT
  deriving (Show)


--------------------------------------------------------------------------------


newtype Processor itrT valT = Processor (itrT -> ProcessResult itrT valT)

process :: Processor itrT valT -> itrT -> ProcessResult itrT valT
process (Processor f) = f


processResult :: Source.Positioned itrT => Processor itrT valT -> itrT -> Either (Source.Position, String) valT
processResult (Processor f) itr = case f itr of
  Processed value _         -> Right value
  OptionFailed itr          -> Left (Source.posOf itr, "parser error")
  ProcessFailed msg itr_msg -> Left (Source.posOf itr_msg, msg)


peekNext :: Iterator.Iterator itrT => Processor itrT (Iterator.Value itrT)
peekNext = Processor impl
  where
    impl itr = case Iterator.curValue itr of
      Just value -> Processed value itr
      Nothing    -> OptionFailed itr


getNext :: Iterator.Iterator itrT => Processor itrT (Iterator.Value itrT)
getNext = Processor impl
  where
    impl itr = case Iterator.curValue itr of
      Just value -> Processed value (Iterator.next itr)
      Nothing    -> OptionFailed itr


getPos :: Source.Positioned itrT => Processor itrT Source.Position
getPos = Processor impl
  where
    impl itr = Processed (Source.posOf itr) itr


getEof :: Iterator.Iterator itrT => Processor itrT Bool
getEof = Processor impl
  where
    impl itr = Processed (Iterator.isEnd itr) itr


optionFail :: Processor itrT a
optionFail = Processor OptionFailed


satisfy :: Iterator.Iterator itrT => (Iterator.Value itrT -> Bool) -> Processor itrT (Iterator.Value itrT)
satisfy pred = Processor impl
  where
    impl itr = case Iterator.curValue itr of
      Just value | pred value -> Processed value (Iterator.next itr)
      _                       -> OptionFailed itr


require :: Processor itrT valT -> String -> Processor itrT valT
require procA msg = Processor impl
  where
    impl itr = case process procA itr of
      OptionFailed itr -> ProcessFailed msg itr
      result           -> result


instance Functor (Processor itrT) where
  fmap = liftM


instance Applicative (Processor itrT) where
  pure :: a -> Processor itrT a
  pure a = Processor (Processed a)

  (<*>) :: Processor itrT (a -> b) -> Processor itrT a -> Processor itrT b
  (<*>) = ap


instance Monad (Processor itrT) where
  (>>=) :: Processor itrT a -> (a -> Processor itrT b) -> Processor itrT b
  procA >>= f = Processor impl
    where
      impl itr = case process procA itr of
        ProcessFailed msg itr_fail -> ProcessFailed msg itr_fail
        OptionFailed itr_fail      -> OptionFailed itr_fail
        Processed a itr_a          -> process (f a) itr_a


instance MonadFail (Processor itrT) where
  fail :: String -> Processor itrT a
  fail msg = Processor (ProcessFailed msg)


instance Alternative (Processor itrT) where
  empty :: Processor itrT a
  empty = Processor OptionFailed

  (<|>) :: Processor itrT a -> Processor itrT a -> Processor itrT a
  procA <|> procB = Processor impl
    where
      impl itr = case process procA itr of
        ProcessFailed msg itr_a -> ProcessFailed msg itr_a
        OptionFailed _          -> process procB itr
        Processed a itr_a       -> Processed a itr_a
