{-# OPTIONS --type-in-type #-}

module Data.Enum where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Data.Char

-------------------------------------------------------------------------------
-- Enum
-------------------------------------------------------------------------------

record Enum (a : Set) : Set where
  field
    {{Ord-super}} : Ord a
    next : a -> Maybe a
    previous : a -> Maybe a
    enumFromTo : a -> a -> List a

open Enum {{...}} public

instance
  Enum-Nat : Enum Nat
  Enum-Nat .next x = Just (Suc x)
  Enum-Nat .previous 0 = Nothing
  Enum-Nat .previous (Suc n) = Just n
  Enum-Nat .enumFromTo m n =
      let k = max (m - n) (n - m)
      in go k m n
    where
      go : Nat -> Nat -> Nat -> List Nat
      go 0 m _ = m :: []
      go (Suc k) m n =
        let m' = if m < n then m + 1 else m - 1
        in m :: go k m' n

  Enum-Int : Enum Int
  Enum-Int .next (Pos n) = Just $ Pos (Suc n)
  Enum-Int .next (NegSuc n) = Just $ neg n
  Enum-Int .previous (Pos 0) = Just $ NegSuc 0
  Enum-Int .previous (Pos (Suc n)) = Just $ Pos n
  Enum-Int .previous (NegSuc n) = Just $ NegSuc (Suc n)
  Enum-Int .enumFromTo m n =
    case m - n of \ where
      (Pos k) -> (\ i -> Pos i + n) <$> enumFromTo k 0
      (NegSuc k) -> (\ i -> Pos i + m) <$> enumFromTo 0 (Suc k)

  Enum-Char : Enum Char
  Enum-Char .next c =
    if c == maxChar
      then Nothing
      else chr <$> next (ord c)
  Enum-Char .previous c =
    if c == minChar
      then Nothing
      else chr <$> previous (ord c)
  Enum-Char .enumFromTo c d = chr <$> enumFromTo (ord c) (ord d)
