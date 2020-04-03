{-# OPTIONS --type-in-type #-}

module Data.Foldable where

open import Prelude

private
  variable
    A B S : Set
    F M : Set -> Set

--------------------------------------------------------------------------------
-- Fold and Foldable
--------------------------------------------------------------------------------

record Fold (S A : Set) : Set where
  field
    foldMap : {{_ : Monoid B}} -> (A -> B) -> S -> B

  fold : {{_ : Monoid A}} -> S -> A
  fold = foldMap identity

  foldr : (A -> B -> B) -> B -> S -> B
  foldr f b as = fromEndo (foldMap (toEndo <<< f) as) b

  foldl : (B -> A -> B) -> B -> S -> B
  foldl f b as =
    (fromEndo <<< fromDual) (foldMap (toDual <<< toEndo <<< flip f) as) b

  foldrM : {{_ : Monad M}} -> (A -> B -> M B) -> B -> S -> M B
  foldrM f b as = let g k a b' = f a b' >>= k in
    foldl g return as b

  foldlM : {{_ : Monad M}} -> (B -> A -> M B) -> B -> S -> M B
  foldlM f b as = let g a k b' = f b' a >>= k in
    foldr g return as b

  null : S -> Bool
  null = untag <<< foldlM (\ _ _ -> left false) true

  length : S -> Nat
  length = foldr (const suc) 0

  find : (A -> Bool) -> S -> Maybe A
  find p = let ensure' p = (\ _ -> maybeToLeft unit <<< ensure p) in
    leftToMaybe <<< foldlM (ensure' p) unit

  at : Nat -> S -> Maybe A
  at n = leftToMaybe <<< foldlM f 0
    where
      f : Nat -> A -> A + Nat
      f k a = if k == n then left a else right (suc k)

  any : (A -> Bool) -> S -> Bool
  any p = isJust <<< find p

  all : (A -> Bool) -> S -> Bool
  all p = not <<< any (not <<< p)

  module _ {{_ : Eq A}} where

    elem : A -> S -> Bool
    elem = any <<< _==_

    notElem : A -> S -> Bool
    notElem x = not <<< elem x

  module _ {{_ : Applicative F}} where

    traverse! : (A -> F B) -> S -> F Unit
    traverse! f = foldr (_*>_ <<< f) (pure unit)

    for! : S -> (A -> F B) -> F Unit
    for! = flip traverse!

  module _ {{_ : Boolean A}} where

    or : S -> A
    or = foldr _||_ bottom

    and : S -> A
    and = foldr _&&_ top

open Fold {{...}} public

sequence! : {{_ : Applicative F}} {{_ : Fold S (F A)}} -> S -> F Unit
sequence! = traverse! identity

Foldable : (Set -> Set) -> Set
Foldable T = forall {A} -> Fold (T A) A

--------------------------------------------------------------------------------
-- Instances
--------------------------------------------------------------------------------

instance
  foldableList : Foldable List
  foldableList .foldMap f = \ where
    [] -> mempty
    (a :: as) -> f a <> foldMap f as

  foldStringChar : Fold String Char
  foldStringChar .foldMap f = foldMap f <<< unpack
