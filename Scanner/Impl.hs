{- HLINT ignore "Use unless" -}
module Scanner.Impl (scan) where

import qualified Data.Char as Char
import Control.Applicative (many, some, optional, (<|>))
import Data.Map.Strict ((!?))
import Data.Maybe (fromMaybe)

import qualified Source
import qualified Stream
import qualified Scanner.Lexemes as Lexemes
import Scanner.Token



-- A scanner is just a special kind of stream processor
type Scanner = Stream.Processor Source.SourceItr


softGet :: Scanner Char
softGet = do
  Stream.peekNext
  Stream.getNext


satisfy :: (Char -> Bool) -> Scanner Char
satisfy predicate = do
  c <- softGet
  if predicate c
    then return c
    else Stream.optionFail


scanWhitespace :: Scanner String
scanWhitespace = many (satisfy Char.isSpace)


scanIdentifier :: Scanner Token
scanIdentifier = do
  first <- satisfy isIdStart
  rest <- many (satisfy isIdContinue)
  let id = first : rest
  return $ fromMaybe (Identifier id) (Lexemes.keywords !? id)
  where
    isIdStart c = c == '_' || Char.isAlpha c
    isIdContinue c = c == '_' || Char.isAlphaNum c


scanNumber :: Scanner Token
scanNumber = do
  intStr <- some (satisfy Char.isDigit)
  maybeFloatStr <- optional fraction
  case maybeFloatStr of
    Just floatStr -> return (Number $ read $ intStr ++ floatStr)
    Nothing       -> return (Number $ read intStr)
  where
    fraction = do
      satisfy (== '.')
      digits <- some (satisfy Char.isDigit)
      return ('.' : digits)


scanPunctuation2 :: Scanner Token
scanPunctuation2 = do
  c <- softGet
  d <- softGet
  maybe Stream.optionFail return (Lexemes.punctuation !? [c, d])


scanPunctuation1 :: Scanner Token
scanPunctuation1 = do
  c <- softGet
  maybe Stream.optionFail return (Lexemes.punctuation !? [c])


scanToken :: Scanner PosToken
scanToken = do
  scanWhitespace
  pos <- Stream.getPos
  token <- scanNumber <|> scanIdentifier <|> scanPunctuation2 <|> scanPunctuation1
  return $ PosToken pos token


allTokens :: Scanner [PosToken]
allTokens = do
  tokens <- some scanToken
  scanWhitespace
  pos <- Stream.getPos
  eof <- Stream.getEof
  if eof
    then return $ tokens ++ [PosToken pos Eof]
    else fail "unrecognized character"


scan :: String -> Either (Source.Position, String) [PosToken]
scan text = Stream.processResult allTokens (Source.begin text)
