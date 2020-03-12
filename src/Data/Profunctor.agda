{-# OPTIONS --type-in-type #-}

module Data.Profunctor where

open import Data.Bifunctor public
open import Prelude

ProfunctorOf : (C D : Category) -> (ob D -> ob C -> Set) -> Set
ProfunctorOf C D = BifunctorOf (Op D) C Sets

Profunctor = ProfunctorOf Sets Sets

Profunctor:hom : (C : Category) -> ProfunctorOf C C (hom C)
Profunctor:hom C .bimap f g h = f >>> h >>> g
  where instance _ = C

instance
  Profunctor:Function = Profunctor:hom Sets
