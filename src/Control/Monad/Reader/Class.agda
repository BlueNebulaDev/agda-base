{-# OPTIONS --type-in-type #-}

module Control.Monad.Reader.Class where

open import Prelude

private variable A : Set

record MonadReader (R : Set) (M : Set -> Set) : Set where
  field
    {{monad}} : Monad M
    ask : M R
    local : (R -> R) -> M ~> M

  asks : (R -> A) -> M A
  asks f = do
    r <- ask
    return (f r)

open MonadReader {{...}} public
