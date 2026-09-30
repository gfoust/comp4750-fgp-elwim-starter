module Parser.Precedence where

import Scanner.Token

import qualified Data.Map.Strict as Map
import Data.Map.Strict (Map, (!))

isUnary :: Operator -> Bool
isUnary Not = True
isUnary Sub = True
isUnary _ = False


isBinary :: Operator -> Bool
isBinary Not = False
isBinary _ = True

operatorPrecedence :: Map Operator Int
operatorPrecedence = Map.fromList [
  (Or,  1),
  (And, 2),
  (Eq,  3),
  (Ne,  3),
  (Lt,  4),
  (Ge,  4),
  (Gt,  4),
  (Le,  4),
  (Add, 5),
  (Sub, 5),
  (Mul, 6),
  (Div, 6),
  (Mod, 6)
  ]

precedenceOf :: Operator -> Int
precedenceOf op = operatorPrecedence ! op
