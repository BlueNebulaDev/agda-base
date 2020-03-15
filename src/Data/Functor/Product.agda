{-# OPTIONS --type-in-type #-}

module Data.Functor.Product where

open import Prelude

-- With this, we can write F * G for product of two endofunctors on Sets.
instance
  Mul:Functor : Mul (Set -> Set)
  Mul:Functor ._*_ F G = \ A -> F A * G A

-- The product of two endofunctors is a functor.
instance
  Functor:Product : forall {F G}
    -> {{_ : Functor F}}
    -> {{_ : Functor G}}
    -> Functor (F * G)
  Functor:Product .map f (Pair: x y) = Pair: (map f x) (map f y)
