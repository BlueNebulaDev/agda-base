{-# OPTIONS --type-in-type #-}

module Data.Pair where

open import Data.Bool
open import Data.Eq
open import Data.Foldable
open import Data.Function
open import Data.Functor
open import Data.Monoid
open import Data.Semigroup
open import Data.Traversable
open import Prim

private variable A B C D : Set

split : (A -> B) -> (A -> C) -> A -> Pair B C
split f g a = (f a , g a)

swap : Pair A B -> Pair B A
swap = split snd fst

dupe : A -> Pair A A
dupe = split id id

uncurry : (A -> B -> C) -> Pair A B -> C
uncurry f (a , b) = f a b

curry : (Pair A B -> C) -> A -> B -> C
curry f a b = f (a , b)

apply : Pair (A -> B) A -> B
apply = uncurry _$_

instance
  eqPair : {{_ : Eq A}} {{_ : Eq B}} -> Eq (Pair A B)
  eqPair ._==_ (a , b) (c , d) = (a == c) && (b == d)

  functorPair : Functor (Pair A)
  functorPair .map f (a , x) = (a , f x)

  bifunctorPair : Bifunctor Pair
  bifunctorPair .bimap f g = split (f <<< fst) (g <<< snd)

  foldablePair : Foldable (Pair A)
  foldablePair .foldMap f (_ , y) = f y

  traversablePair : Traversable (Pair A)
  traversablePair .traverse f (x , y) = _,_ x <$> f y

  semigroupProductSet : Semigroup (Product Set)
  semigroupProductSet ._<>_ A B =
    toProduct $ Pair (fromProduct A) (fromProduct B)

  monoidProductSet : Monoid (Product Set)
  monoidProductSet .mempty = toProduct Unit
