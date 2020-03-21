{-# OPTIONS --type-in-type #-}

module Data.Profunctor where

open import Data.Bifunctor public
open import Prelude

private variable A B C D : Set

record Profunctor (P : Set -> Set -> Set) : Set where
  field
    dimap : (A -> B) -> (C -> D) -> P B C -> P A D

  lmap : (A -> B) -> P B C -> P A C
  lmap f = dimap f identity

  rmap : (B -> C) -> P A B -> P A C
  rmap f = dimap identity f

open Profunctor {{...}} public

instance
  profunctorFunction : Profunctor Function
  profunctorFunction .dimap f g h = f >>> h >>> g
