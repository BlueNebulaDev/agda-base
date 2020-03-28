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

  count : S -> Nat
  count = foldl (\ c _ -> suc c) 0

  any : (A -> Bool) -> S -> Bool
  any p = getAny <<< foldMap (any: <<< p)

  all : (A -> Bool) -> S -> Bool
  all p = getAll <<< foldMap (all: <<< p)

  find : (A -> Bool) -> S -> Maybe A
  find p s = let f a = when (p a) $ just (first: a) in
    maybe nothing (just <<< getFirst) (foldMap f s)

  at : Nat -> S -> Maybe A
  at n = snd <<< foldl f (0 , nothing)
    where
      f :  Nat * Maybe A -> A -> Nat * Maybe A
      f (k , m) a = (suc k , if k == n then just a else m)

  head : S -> Maybe A
  head = at 0

  module _ {{_ : Eq A}} where

    elem : A -> S -> Bool
    elem = any <<< _==_

    notElem : A -> S -> Bool
    notElem x = not <<< elem x

  module _ {{_ : Applicative F}} where

    traverse- : (A -> F B) -> S -> F Unit
    traverse- f = foldr (_*>_ <<< f) (pure unit)

    for- : S -> (A -> F B) -> F Unit
    for- = flip traverse-

  module _ {{_ : Monoid S}} where

    cons : A -> S -> S
    cons a s = singleton a <> s

    snoc : S -> A -> S
    snoc s a = s <> singleton a

    replicate : Nat -> A -> S
    replicate n a = applyN (cons a) n empty

    takeWhile : (A -> Bool) -> S -> S
    takeWhile p = foldl f empty
      where
        f : S -> A -> S
        f s a with p a
        ... | true = s <> singleton a
        ... | false = s

    dropWhile : (A -> Bool) -> S -> S
    dropWhile p = snd <<< foldl f (true , empty)
      where
        f : Bool * S -> A -> Bool * S
        f (b , s) a with b | p a
        ... | true | true = (true , s)
        ... | true | false = (false , s <> singleton a)
        ... | false | _ = (false , s <> singleton a)

    deleteAt : Nat -> S -> S
    deleteAt n = snd <<< foldl f (0 , empty)
      where
        f : Nat * S -> A -> Nat * S
        f (k , s) a = (suc k , if k == n then s else snoc s a)

    tail : S -> Maybe S
    tail s = if null s then nothing else deleteAt 0 s

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