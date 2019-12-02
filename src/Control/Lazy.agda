{-# OPTIONS --type-in-type #-}

module Control.Lazy where

open import Control.Category
open import Data.Functor

open import Agda.Builtin.Coinduction public
  renaming (
    ∞ to Lazy;
    ♯_ to delay;
    ♭ to force
  )

-- Lazy is a functor.
instance
  Functor:Lazy : Endofunctor Sets Lazy
  Functor:Lazy .map f x = delay (f (force x))
