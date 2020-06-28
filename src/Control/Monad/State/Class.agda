{-# OPTIONS --type-in-type #-}

module Control.Monad.State.Class where

open import Prelude

private variable A : Set

record MonadState (S : Set) (M : Set -> Set) : Set where
  field
    {{monad}} : Monad M
    get : M S
    put : S -> M Unit

  state : (S -> A * S) -> M A
  state f = do
    s0 <- get
    let (a , s1) = f s0
    put s1
    return a

  modify : (S -> S) -> M Unit
  modify f = state (λ s -> (unit , f s))

  gets : (S -> A) -> M A
  gets f = do
    s <- get
    return (f s)

open MonadState {{...}} public
