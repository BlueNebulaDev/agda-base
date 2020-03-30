{-# OPTIONS --type-in-type #-}

module Data.Foldable where

open import Prelude

private
  variable
    A B : Set
    F G M : Set -> Set

record Foldable (S A : Set) : Set where
  field
    singleton : A -> S
    foldMap : {{_ : Monoid B}} -> (A -> B) -> S -> B

  fold : {{_ : Monoid A}} -> S -> A
  fold = foldMap identity

  foldr : (A -> B -> B) -> B -> S -> B
  foldr f b s = appEndo (foldMap (endo: <<< f) s) b

  foldl : (B -> A -> B) -> B -> S -> B
  foldl f b s =
    (appEndo <<< getDual) (foldMap (dual: <<< endo: <<< flip f) s) b

  foldrM : {{_ : Monad M}} -> (A -> B -> M B) -> B -> S -> M B
  foldrM f b s = let g k a b' = f a b' >>= k in
    foldl g return s b

  foldlM : {{_ : Monad M}} -> (B -> A -> M B) -> B -> S -> M B
  foldlM f b s = let g a k b' = f b' a >>= k in
    foldr g return s b

  null : S -> Bool
  null = untag <<< foldlM (\ _ _ -> left false) true

  nonempty : S -> Bool
  nonempty = not <<< null

  count : S -> Nat
  count = foldr (const suc) 0

  find : (A -> Bool) -> S -> Maybe A
  find p = let ensure' p = (\ _ -> maybeToLeft unit <<< ensure p) in
    leftToMaybe <<< foldlM (ensure' p) unit

  any : (A -> Bool) -> S -> Bool
  any p = isJust <<< find p

  all : (A -> Bool) -> S -> Bool
  all p = not <<< any (not <<< p)

  at : Nat -> S -> Maybe A
  at n = leftToMaybe <<< foldlM f 0
    where
      f : Nat -> A -> A + Nat
      f k a = if k == n then left a else right (suc k)

  head : S -> Maybe A
  head = at 0

  module _ {{_ : Eq A}} where

    elem : A -> S -> Bool
    elem = any <<< _==_

    notElem : A -> S -> Bool
    notElem x = not <<< elem x

  module _ {{_ : Applicative F}} where

    foreach : S -> (A -> F B) -> F Unit
    foreach s f = foldr (_*>_ <<< f) (pure unit) s

open Foldable {{...}} public

module _ {{_ : forall {A} -> Foldable (F A) A}} where

  and : F Bool -> Bool
  and = foldr _&&_ true

  or : F Bool -> Bool
  or = foldr _||_ false

  sequence- :  {{_ : Applicative G}}
    -> F (G A) -> G Unit
  sequence- = foldr _*>_ (pure unit)

  --intercalate : {{_ : Monoid A}} -> A -> F A -> A
  --intercalate sep xs = (foldl go true mempty xs)

instance
  foldableList : Foldable (List A) A
  foldableList .singleton x = x :: []
  foldableList .foldMap f = \ where
    [] -> empty
    (a :: as) -> f a <> foldMap f as

  foldableString : Foldable (String) Char
  foldableString .singleton c = pack (singleton c)
  foldableString .foldMap f s = foldMap f (unpack s)
