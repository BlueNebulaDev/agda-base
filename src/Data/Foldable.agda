{-# OPTIONS --type-in-type #-}

module Data.Foldable where

-- A free monoid on a type X consists of a monoid F X together with a function
-- lift : X -> F X such that for any monoid M and any function f : X -> M,
-- there is a unique monoid homomorphism foldMap f : F X -> M satisfying
-- lift >>> foldMap f = f. If F X is a free monoid on X for all X, then
-- the construction F is called a free-monoid constructor. A foldable F is a
-- free monoid constructor without lift, without the monoid requirement on F X
-- and without the unique-monoid-homomorphism requirement on foldMap f.

open import Control.Applicative
open import Control.Category
open import Data.Bool
open import Data.Eq
open import Data.Function
open import Data.Monoid
open import Data.Nat
open import Data.Unit

record Foldable (F : Set -> Set) : Set where
  constructor Foldable:
  field
    foldMap : forall {X M} {{_ : Monoid M}}
      -> (X -> M) -> F X -> M

  fold : forall {X} {{_ : Monoid X}} -> F X -> X
  fold = foldMap id

  foldr : forall {X Y} -> (X -> Y -> Y) -> Y -> F X -> Y
  foldr f y x = foldMap {{Monoid:<<< Sets}} f x y

  foldl : forall {X Y} -> (Y -> X -> Y) -> Y -> F X -> Y
  foldl f y x = foldMap {{Op (Monoid:<<< Sets)}} (flip f) x y

  null : forall {X} -> F X -> Bool
  null = foldMap {{Monoid:&&}} (const true)

  size : forall {X} -> F X -> Nat
  size = foldMap $ const $ suc zero

  elem : forall {X} {{_ : Eq X}} -> X -> F X -> Bool
  elem x = foldMap {{Monoid:||}} (_== x)

  Nonempty : forall {X} -> F X -> Set
  Nonempty xs = Assert (not (null xs))

  traverse- : forall {X Y G} {{_ : Applicative G}}
    -> (X -> G Y) -> F X -> G Unit
  traverse- f = foldr (f >>> _*>_) (pure tt)

  for- : forall {X Y G} {{_ : Applicative G}}
    -> F X -> (X -> G Y) -> G Unit
  for- = flip traverse-

open Foldable {{...}} public
