{-# OPTIONS --type-in-type #-}

module Data.Functor.Identity where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Data.Foldable
open import String.Show

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a : Set

-------------------------------------------------------------------------------
-- Identity
-------------------------------------------------------------------------------

record Identity (a : Set) : Set where
  constructor toIdentity
  field runIdentity : a

open Identity public

instance
  Eq-Identity : {{Eq a}} -> Eq (Identity a)
  Eq-Identity ._==_ x y = runIdentity x == runIdentity y

  Ord-Identity : {{Ord a}} -> Ord (Identity a)
  Ord-Identity .compare x y = compare (runIdentity x) (runIdentity y)

  Semigroup-Identity : {{Semigroup a}} -> Semigroup (Identity a)
  Semigroup-Identity ._<>_ x y = toIdentity (runIdentity x <> runIdentity y)

  Monoid-Identity : {{Monoid a}} -> Monoid (Identity a)
  Monoid-Identity .neutral = toIdentity neutral

  Foldable-Identity : Foldable Identity
  Foldable-Identity .foldr f z x = f (runIdentity x) z

  Functor-Identity : Functor Identity
  Functor-Identity .map f = toIdentity <<< f <<< runIdentity

  Applicative-Identity : Applicative Identity
  Applicative-Identity .pure = toIdentity
  Applicative-Identity ._<*>_ = map <<< runIdentity

  Monad-Identity : Monad Identity
  Monad-Identity ._>>=_ x k = k (runIdentity x)

  Show-Identity : {{Show a}} -> Show (Identity a)
  Show-Identity .showsPrec d x = showParen (d > appPrec)
    (showString "toIdentity " <<< showsPrec appPrec+1 (runIdentity x))
