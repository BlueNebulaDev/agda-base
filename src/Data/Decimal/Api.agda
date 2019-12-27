{-# OPTIONS --type-in-type #-}

module Data.Decimal.Api where

open import Data.Decimal.Base

-- Add two decimal numbers and a carry digit following the school-taught
-- algorithm.

open import Data.Digit
open import Data.List
open import Data.Product

add : Decimal -> Decimal -> Digit -> Decimal
add [] [] 0d = [] -- prevents adding leading zeros
add [] [] carry = [ carry ]
add [] (n :: ns) carry =
  let (sum , carry') = Digit.halfAdd n carry
  in sum :: add [] ns carry'
add (m :: ms) [] carry =
  let (sum , carry') = Digit.halfAdd m carry
  in sum :: add ms [] carry'
add (m :: ms) (n :: ns) carry =
  let (sum , carry') = Digit.fullAdd m n carry
  in sum :: add ms ns carry'

-- This allows us to use _+_ for adding decimals.

open import Notation.Add

instance
  Add:Decimal : Add Decimal
  Add:Decimal = Add: (\ m n -> add m n 0d)

-- Convert a unary natural number to a decimal number.

open import Data.Nat.Base

fromNat : Nat -> Decimal
fromNat zero = [ 0d ]
fromNat (suc n) = fromNat n + [ 1d ]

-- Convert a decimal number to a unary natural number.

toNat : Decimal -> Nat
toNat [] = 0
toNat (d :: ds) = Digit.toNat d + 10 * toNat ds

-- This allows us to use natural number literals to write decimals.

open import Data.Unit public
open import Notation.Number public

instance
  Number:Decimal : Number Decimal
  Number:Decimal = record {
      Constraint = \ _ -> Unit;
      fromNat = \ n -> fromNat n
    }
