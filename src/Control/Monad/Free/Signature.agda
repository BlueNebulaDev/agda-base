{-# OPTIONS --type-in-type #-}

module Control.Monad.Free.Signature where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Control.Monad.Kleisli
open import Control.Recursion

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a b : Set
    sig : Signature

-------------------------------------------------------------------------------
-- Free
-------------------------------------------------------------------------------

record Free (sig : Signature) (a : Set) : Set where
  constructor aFree
  field unFree : Fix (ConstS a + sig)

open Free public

pattern finished x arg = aFree (sup (left x) arg)
pattern roll symb arg = aFree (sup (right symb) arg)

inn : Operation sig (Free sig a) -> Free sig a
inn (anOperation symb arg) = roll symb (arg >>> unFree)

instance
  Triple-Free : Triple (Free sig)
  Triple-Free .joinMap k (finished x _) = k x
  Triple-Free .joinMap k (roll symb arg) =
    let arg' x = joinMap k (aFree (arg x))
    in inn (anOperation symb arg')
  Triple-Free .return x = finished x absurd

  Functor-Free : Functor (Free sig)
  Functor-Free .map = liftM

  Applicative-Free : Applicative (Free sig)
  Applicative-Free .pure = return
  Applicative-Free ._<*>_ = ap

  Monad-Free : Monad (Free sig)
  Monad-Free ._>>=_ = bind
