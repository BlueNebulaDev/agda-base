module Control.Comonad.Cofree where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Control.Comonad

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a : Set
    f : Set -> Set

-------------------------------------------------------------------------------
-- Cofree
-------------------------------------------------------------------------------

record Cofree (f : Set -> Set) (a : Set) : Set where
  coinductive
  field
    value : a
    unwrap : f (Cofree f a)

instance
  Functor-Cofree : {{Functor f}} -> Functor (Cofree f)
  Functor-Cofree .map f x = \ where
    .Cofree.value -> f (Cofree.value x)
    .Cofree.unwrap -> map (map f) (Cofree.unwrap x)

  Comonad-Cofree : {{Functor f}} -> Comonad (Cofree f)
  Comonad-Cofree .extend h cf = \ where
    .Cofree.value -> h cf
    .Cofree.unwrap -> map (extend h) (Cofree.unwrap cf)
  Comonad-Cofree .extract cf = Cofree.value cf
