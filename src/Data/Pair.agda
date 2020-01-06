{-# OPTIONS --type-in-type #-}

module Data.Pair where

-- Pair is used to construct dependent pairs. It is a record with constructor
-- _,_ and fields fst and snd.

open import Agda.Builtin.Sigma public
  renaming (Σ to Pair)

-- The exists function should be thought of as the existensial quantifier, dual
-- to forall.

exists : forall {X} (P : X -> Set) -> Set
exists {X} P = Pair X P 

-- This instance allows use to use _*_ for the Cartesian product.

open import Notation.Mul

instance
  Mul:Set : Mul Set
  Mul:Set = Mul: (\ X Y -> Pair X (\ _ -> Y))

-- Categorically speaking, for any two types X and Y, both X * Y and Y * X
-- are products of X and Y. The function swap serves as proof that they are
-- isomorphic.

swap : forall {X Y} -> X * Y -> Y * X
swap (x , y) = (y , x)

-- The pair function is evidence that _*_ satisfies the universal property of
-- products in the category Sets. You can also think of it as the unfold
-- operation for _*_.

pair : {X Y Z : Set} -> (X -> Y) -> (X -> Z) -> X -> Y * Z
pair f g x = (f x , g x)

-- The uncurried version of _*_ forms a bifunctor. The map operation of this
-- bifunctor in uncurried form is cross.

cross : forall {X X' Y Y'} -> (X -> Y) -> (X' -> Y') -> X * X' -> Y * Y'
cross f g (x , y) = (f x , g y)

-- The function uncurry can be thought of as the fold operation for _*_.

uncurry : {X Y Z : Set} -> (X -> Y -> Z) -> X * Y -> Z
uncurry f (x , y) = f x y

-- The inverse of uncurry is curry. These two functions witness an isomorphism
-- between X * Y -> Z and X -> Y -> Z. They also serve as the left and right
-- adjuncts of the adjunction between Writer Y and Reader Y.

curry : {X Y Z : Set} -> (X * Y -> Z) -> X -> Y -> Z
curry f x y = f (x , y)

-- The function curry is also evidence that Y -> Z satisfies the universal
-- property of being an exponential object in the category Sets. Recall that
-- that exponential objects come with a function apply : (Y -> Z) * Y -> Z such
-- that apply (curry f x , y) = f (x , y) for any f : X * Y -> Z.

apply : {Y Z : Set} -> (Y -> Z) * Y -> Z
apply (g , y) = g y

-- Duplicate an argument.

dupe : forall {X} -> X -> X * X
dupe x = (x , x)
