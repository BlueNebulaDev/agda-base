{-# OPTIONS --type-in-type #-}

module Data.Functor.Const where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Data.Foldable

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a b : Set

-------------------------------------------------------------------------------
-- Const
-------------------------------------------------------------------------------

record Const (a b : Set) : Set where
  constructor Const:
  field getConst : a

open Const public

instance
  Eq-Const : {{_ : Eq a}} -> Eq (Const a b)
  Eq-Const ._==_ (Const: x) (Const: y) = x == y

  Ord-Const : {{_ : Ord a}} -> Ord (Const a b)
  Ord-Const ._<_ (Const: x) (Const: y) = x < y

  Semigroup-Const : {{_ : Semigroup a}} -> Semigroup (Const a b)
  Semigroup-Const ._<>_ (Const: x) (Const: y) = Const: (x <> y)

  Monoid-Const : {{_ : Monoid a}} -> Monoid (Const a b)
  Monoid-Const .mempty = Const: mempty

  Foldable-Const : Foldable (Const a)
  Foldable-Const .foldMap _ _ = mempty

  Functor-Const : Functor (Const a)
  Functor-Const .map _ (Const: x) = Const: x

  Functor-Flip-Const : Functor (Flip Const b)
  Functor-Flip-Const .map f (Flip: (Const: x)) = Flip: (Const: (f x))

  Bifunctor-Const : Bifunctor Const
  Bifunctor-Const = record {}

  Contravariant-Const : Contravariant (Const a)
  Contravariant-Const .contramap f = Const: <<< getConst

  Applicative-Const : {{_ : Monoid a}} -> Applicative (Const a)
  Applicative-Const .pure _ = Const: mempty
  Applicative-Const ._<*>_ (Const: f) (Const: a) = Const: (f <> a)

  Show-Const : {{_ : Show a}} -> Show (Const a b)
  Show-Const .showsPrec d (Const: x) = showParen (d > appPrec)
    (showString "Const: " <<< showsPrec appPrec+1 x)
