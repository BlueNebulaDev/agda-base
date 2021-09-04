{-# OPTIONS --type-in-type #-}

module Data.Bits where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

-------------------------------------------------------------------------------
-- Bits
-------------------------------------------------------------------------------

record Bits (a : Set) : Set where
  infixl 5 _:|:_
  infixl 6 _xor_
  infixl 7 _:&:_
  field
    bitSize : a -> Nat
    zeroBits : a
    oneBits : a
    _:|:_ : a -> a -> a
    _xor_ : a -> a -> a
    _:&:_ : a -> a -> a
    shift : a -> Int -> a
    rotate : a -> Int -> a
    bit : Nat -> a
    testBit : a -> Nat -> Bool
    isSigned : a -> Bool
    popCount : a -> Nat

  complement : a -> a
  complement x = x xor oneBits

  clearBit : a -> Nat -> a
  clearBit x i = x :&: complement (bit i)

  setBit : a -> Nat -> a
  setBit x i = x :|: bit i

  assignBit : a -> Nat -> Bool -> a
  assignBit b n True = setBit b n
  assignBit b n False = clearBit b n

  notBit : a -> Nat -> a
  notBit x i = x xor (bit i)

  shiftL : a -> Nat -> a
  shiftL x i = shift x (Pos i)

  shiftR : a -> Nat -> a
  shiftR x i = shift x (neg i)

  rotateL : a -> Nat -> a
  rotateL x i = rotate x (Pos i)

  rotateR : a -> Nat -> a
  rotateR x i = rotate x (neg i)

  countLeadingZeros : a -> Nat
  countLeadingZeros x =
      let n = pred (bitSize x) in monus n (go n)
    where
      go : Nat -> Nat
      go 0 = 0
      go n@(Suc n-1) = if testBit x n then n else go n-1

  countTrailingZeros : a -> Nat
  countTrailingZeros x =
     let n = pred (bitSize x) in go n 0
    where
      go : Nat -> Nat -> Nat
      go 0 n = n
      go (Suc m) n =
        if testBit x n then n
        else go m (n + 1)

open Bits {{...}} public
