{-# OPTIONS --type-in-type #-}

module String.Parser where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude hiding (bool)

open import Control.Alternative
open import Data.Char as Char using ()
open import Data.List as List using ()
open import Data.String as String using ()
open import Data.Traversable

-------------------------------------------------------------------------------
-- Re-exports
-------------------------------------------------------------------------------

open Control.Alternative public

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a b c : Set

-------------------------------------------------------------------------------
-- Parser
-------------------------------------------------------------------------------

data Consumed : Set where
  yes : Consumed
  no : Consumed

data Result (a : Set) : Set where
  ok : Consumed -> Pair a String -> Result a
  err : Consumed -> Result a

record Parser (a : Set) : Set where
  constructor toParser
  field runParser : String -> Result a

open Parser

-------------------------------------------------------------------------------
-- Instances
-------------------------------------------------------------------------------

private
  pureParser : a -> Parser a
  pureParser x = toParser \ where
    input -> ok no (x , input)

  bindParser : Parser a -> (a -> Parser b) -> Parser b
  bindParser m k = toParser \ where
    input -> case runParser m input of \ where
      (ok no (x , rest)) -> runParser (k x) rest
      (err no) -> err no
      (ok yes (x , rest)) -> case runParser (k x) rest of \ where
        (ok c out) -> ok c out
        (err c) -> err c
      (err yes) -> err yes

  mapParser : (a -> b) -> Parser a -> Parser b
  mapParser f x = bindParser x (f >>> pureParser)

  apParser : Parser (a -> b) -> Parser a -> Parser b
  apParser p q = bindParser p \ f -> bindParser q \ x -> pureParser (f x)

instance
  Functor-Parser : Functor Parser
  Functor-Parser .map = mapParser

  Applicative-Parser : Applicative Parser
  Applicative-Parser .pure = pureParser
  Applicative-Parser ._<*>_ = apParser

  Monad-Parser : Monad Parser
  Monad-Parser ._>>=_ = bindParser

  Alternative-Parser : Alternative Parser
  Alternative-Parser .azero = toParser \ where
    input -> err no
  Alternative-Parser ._<|>_ l r = toParser \ where
    input -> case runParser l input of \ where
      (err no) -> case runParser r input of \ where
        (err no) -> err no
        (ok no out) -> ok no out
        res -> res
      res -> res

-------------------------------------------------------------------------------
-- Combinators
-------------------------------------------------------------------------------

try : Parser a -> Parser a
try p = toParser \ where
  input -> case runParser p input of \ where
    (err yes) -> err no
    res -> res

notFollowedBy : Parser a -> Parser Unit
notFollowedBy p = toParser \ where
  input -> case runParser p input of \ where
    (ok _ _) -> err no
    (err _) -> ok no (tt , input)

option : a -> Parser a -> Parser a
option a p = p <|> pure a

{-# TERMINATING #-}
many1 many : Parser a -> Parser (List a)
many1 a = (| a :: many a |)
many a = option [] (many1 a)

optional : Parser a -> Parser (Maybe a)
optional a = (| just a | nothing |)

choose : Parser a -> Parser b -> Parser (Either a b)
choose a b = (| left a | right b |)

exactly : Nat -> Parser a -> Parser (List a)
exactly 0 p = pure []
exactly n p = List.sequence (List.replicate n p)

between : Parser a -> Parser b -> Parser c -> Parser c
between p p' q = p *> q <* p'

skipMany : Parser a -> Parser Unit
skipMany p = many p *> pure tt

skipMany1 : Parser a -> Parser Unit
skipMany1 p = many1 p *> pure tt

sepBy1 : Parser a -> Parser b -> Parser (List a)
sepBy1 p sep = (| p :: many (sep *> p) |)

sepBy : Parser a -> Parser b -> Parser (List a)
sepBy p sep = option [] (sepBy1 p sep)

endBy : Parser a -> Parser b -> Parser (List a)
endBy p sep = many (p <* sep)

endBy1 : Parser a -> Parser b -> Parser (List a)
endBy1 p sep = many1 (p <* sep)

{-# TERMINATING #-}
prefix : (a -> b) -> Parser (b -> b) -> Parser a -> Parser b
prefix wrap op p = op <*> prefix wrap op p <|> wrap <$> p

{-# TERMINATING #-}
postfix : (a -> b) -> Parser a -> Parser (b -> b) -> Parser b
postfix wrap p op = (| (wrap <$> p) # rest |)
  where rest = option id (| op >>> rest |)

{-# TERMINATING #-}
infixl1 : (a -> b) -> Parser a -> Parser (b -> a -> b) -> Parser b
infixl1 wrap p op = postfix wrap p (| flip op p |)

{-# TERMINATING #-}
infixr1 : (a -> b) -> Parser a -> Parser (a -> b -> b) -> Parser b
infixr1 wrap p op = (| p # (| flip op (infixr1 wrap p op) |) <|> pure wrap |)

chainl1 : Parser a -> Parser (a -> a -> a) -> Parser a
chainl1 = infixl1 id

chainl : Parser a -> Parser (a -> a -> a) -> a -> Parser a
chainl p op a = option a (chainl1 p op)

chainr1 : Parser a -> Parser (a -> a -> a) -> Parser a
chainr1 = infixr1 id

chainr : Parser a -> Parser (a -> a -> a) -> a -> Parser a
chainr p op a = option a (chainr1 p op)

-------------------------------------------------------------------------------
-- Char parsers
-------------------------------------------------------------------------------

anyChar : Parser Char
anyChar = toParser \ where
  s -> if s == ""
    then err no
    else ok yes (String.uncons s {{trustMe}})

eof : Parser Unit
eof = notFollowedBy anyChar

satisfy : (Char -> Bool) -> Parser Char
satisfy test = do
  c <- anyChar
  if test c then pure c else azero

skipWhile : (Char -> Bool) -> Parser Unit
skipWhile p = do
  c <- anyChar
  if p c then pure tt else azero

skipAll : Parser Unit
skipAll = skipWhile (const true)

char : Char -> Parser Char
char c = satisfy (c ==_)

oneOf : List Char -> Parser Char
oneOf cs = satisfy (\ c -> List.elem c cs)

noneOf : List Char -> Parser Char
noneOf cs = satisfy (\ c -> List.notElem c cs)

alpha : Parser Char
alpha = satisfy Char.isAlpha

lower : Parser Char
lower = satisfy Char.isLower

upper : Parser Char
upper = satisfy (\ c -> Char.isAlpha c && not (Char.isLower c))

digit : Parser Char
digit = satisfy Char.isDigit

hexDigit : Parser Char
hexDigit = satisfy Char.isHexDigit

alphaNum : Parser Char
alphaNum = alpha <|> digit

space : Parser Char
space = satisfy Char.isSpace

skipSpaces : Parser Unit
skipSpaces = skipMany space

newline : Parser Char
newline = char '\n'

crlf : Parser Char
crlf = char '\r' *> newline

endOfLine : Parser Char
endOfLine = newline <|> crlf

tab : Parser Char
tab = char '\t'

-------------------------------------------------------------------------------
-- String parsers
-------------------------------------------------------------------------------

string : String -> Parser String
string = map String.pack <<< traverse char <<< String.unpack

{-# TERMINATING #-}
word : Parser String
word1 : Parser String
word = option "" word1
word1 = (| String.cons alpha word |)

takeWhile : (Char -> Bool) -> Parser String
takeWhile p = toParser (ok yes <<< String.break p)

takeAll : Parser String
takeAll = takeWhile (const true)

-------------------------------------------------------------------------------
-- Parsers for numbers
-------------------------------------------------------------------------------

nat : Parser Nat
nat = chainl1 digit' (pure \ m n -> 10 * m + n)
  where
    digit' : Parser Nat
    digit' = do
      n <- digit
      pure (Char.toDigit n {{trustMe}})

int : Parser Int
int = (| neg (char '-' *> nat) | pos (char '+' *> nat) | pos nat |)

-------------------------------------------------------------------------------
-- Misc. parsers
-------------------------------------------------------------------------------

fully : Parser a -> Parser a
fully = between skipSpaces eof

lexeme : Parser a -> Parser a
lexeme p = p <* skipSpaces

symbol : String -> Parser String
symbol = lexeme <<< string

token : Parser a -> Parser a
token = lexeme <<< try

keyword : String -> Parser Unit
keyword s = token (string s *> notFollowedBy alphaNum)

-------------------------------------------------------------------------------
-- Executing parsers
-------------------------------------------------------------------------------

execParser : Parser a -> String -> Maybe a
execParser p input = case runParser p input of \ where
 (ok _ (x , _)) -> just x
 _ -> nothing
