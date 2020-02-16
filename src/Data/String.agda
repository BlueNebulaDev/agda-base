{-# OPTIONS --type-in-type #-}

module Data.String where

open import Data.String.Base public

module String where

  -- Functions for converting String to/from List Char.

  open import Agda.Builtin.String as Builtin

  toList = Builtin.primStringToList
  fromList = Builtin.primStringFromList
  show = Builtin.primShowString

  -- Convert a Char to a String.

  open import Data.Char
  open import Data.List

  fromChar : Char -> String
  fromChar c = fromList (pure c)

  -- Get the length of a string.

  open import Data.Nat

  length : String -> Nat
  length = toList >>> size

  -- Determine if a string is a prefix of another string.

  open import Data.Bool

  startsWith : String -> String -> Bool
  startsWith s s' = List.isPrefixOf (toList s) (toList s')

  -- Remove the given prefix from a string if it has it.

  open import Data.Function
  open import Data.Maybe

  stripPrefix : String -> String -> Maybe String
  stripPrefix s s' = fromList <$> List.stripPrefix (toList s) (toList s')

  -- Pad a string with a character up to some desired length.

  padRight : Nat -> Char -> String -> String
  padRight desiredLength padChar s =
    let replicated = List.replicate (desiredLength - length s) (fromChar padChar)
    in s ++ (foldl _++_ "" replicated)

  padLeft : Nat -> Char -> String -> String
  padLeft desiredLength padChar s =
    let replicated = List.replicate (desiredLength - length s) (fromChar padChar)
    in (foldl _++_ "" replicated) ++ s

  -- Concatenate a list of strings into one string.

  concat : List String -> String
  concat [] = ""
  concat (str :: strs) = str ++ concat strs

  -- Split a nonmepty string into a head and a tail.

  open import Data.Pair

  uncons : String -> Maybe (Char * String)
  uncons s = case toList s of \ where
    [] -> nothing
    (c :: cs) -> just (Pair: c (fromList cs))

  -- Get the head of a nonempty string.

  head : String -> Maybe Char
  head = map fst <<< uncons

  -- Get the tail of a nonempty string.

  tail : String -> Maybe String
  tail = map snd <<< uncons

  -- Prepend a character to a string.

  cons : Char -> String -> String
  cons c s = fromList (c :: toList s)

  -- Tell Agda to use the Haskell versions of some of the functions above
  -- during compilation.

  {-# FOREIGN GHC import qualified Data.Text as Text #-}
  {-# COMPILE GHC length = toInteger . Text.length #-}
  {-# COMPILE GHC startsWith = Text.isPrefixOf #-}
  {-# COMPILE GHC stripPrefix = Text.stripPrefix #-}
  {-# COMPILE GHC uncons = Text.uncons #-}
  {-# COMPILE GHC cons = Text.cons #-}
