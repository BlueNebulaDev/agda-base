{-# OPTIONS --type-in-type #-}

module Data.Traversable where

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
    a b c s : Set
    f t : Set -> Set

-------------------------------------------------------------------------------
-- Traversable
-------------------------------------------------------------------------------

record Traversable (t : Set -> Set) : Set where
  field
    overlap {{Functor-super}} : Functor t
    overlap {{Foldable-super}} : Foldable t
    traverse : {{_ : Applicative f}} -> (a -> f b) -> t a -> f (t b)

  sequence : {{_ : Applicative f}} -> t (f a) -> f (t a)
  sequence = traverse id

  for : {{_ : Applicative f}} -> t a -> (a -> f b) -> f (t b)
  for = flip traverse

open Traversable {{...}} public

instance
  Traversable-Maybe : Traversable Maybe
  Traversable-Maybe .traverse f m with m
  ... | Nothing = pure Nothing
  ... | Just x = (| Just (f x) |)

  Traversable-List : Traversable List
  Traversable-List .traverse f l with l
  ... | [] = pure []
  ... | x :: xs = (| _::_ (f x) (traverse f xs) |)

-------------------------------------------------------------------------------
-- StateL, StateR helpers
-------------------------------------------------------------------------------

private
  record StateL (s a : Set) : Set where
    constructor StateL:
    field runStateL : s -> s * a

  open StateL

  record StateR (s a : Set) : Set where
    constructor StateR:
    field runStateR : s -> s * a

  open StateR

  instance
    Functor-StateL : Functor (StateL s)
    Functor-StateL .map f (StateL: k) = StateL: \ s ->
      let (s' , v) = k s in (s' , f v)

    Functor-StateR : Functor (StateR s)
    Functor-StateR .map f (StateR: k) = StateR: \ s ->
      let (s' , v) = k s in (s' , f v)

    Applicative-StateL : Applicative (StateL s)
    Applicative-StateL .pure x = StateL: \ s -> (s , x)
    Applicative-StateL ._<*>_ (StateL: kf) (StateL: kv) = StateL: \ s ->
      let
        (s' , f) = kf s
        (s'' , v) = kv s'
      in
        (s'' , f v)

    Applicative-StateR : Applicative (StateR s)
    Applicative-StateR .pure x = StateR: \ s -> (s , x)
    Applicative-StateR ._<*>_ (StateR: kf) (StateR: kv) = StateR: \ s ->
      let
        (s' , v) = kv s
        (s'' , f) = kf s'
      in
        (s'' , f v)

-------------------------------------------------------------------------------
-- mapAccumL & mapAccumR
-------------------------------------------------------------------------------

mapAccumL : {{_ : Traversable t}} -> (a -> b -> a * c) -> a -> t b -> a * t c
mapAccumL f s t = runStateL (traverse (StateL: <<< flip f) t) s

mapAccumR : {{_ : Traversable t}} -> (a -> b -> a * c) -> a -> t b -> a * t c
mapAccumR f s t = runStateR (traverse (StateR: <<< flip f) t) s
