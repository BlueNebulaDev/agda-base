{-# OPTIONS --type-in-type #-}

module Data.List where

private variable A B C : Set

open import Agda.Builtin.List public using (List; [])
open import Agda.Builtin.List public renaming (_∷_ to _::_)
open import Control.Alternative using (Alternative)
open import Control.Alternative using (_<|>_; empty)
open import Control.Applicative using (Applicative)
open import Control.Applicative public using (_<*>_; _*>_; pure)
open import Control.Monad using (Monad)
open import Control.Monad public using (_>>=_; _=<<_; return; join)
open import Data.Bool using (Bool; false; true; if_then_else_; _||_; _&&_)
open import Data.Eq using (Eq)
open import Data.Eq public using (_==_; _/=_)
open import Data.Foldable using (Foldable)
open import Data.Foldable public using (foldMap; foldr; foldl)
open import Data.Function using (_$_; flip; _<<<_)
open import Data.Functor using (Functor)
open import Data.Functor public using (map)
open import Data.Maybe using (Maybe; just; nothing)
open import Data.Monoid using (Monoid; mempty)
open import Data.Nat using (Nat; suc; _+_; -_; _-_; _<_)
open import Data.Ord using (Ord)
open import Data.Ord public using (compare; LT; GT; EQ)
open import Data.Pair using (Pair; _,_)
open import Data.Semigroup using (Semigroup)
open import Data.Semigroup public using (_<>_)
open import Data.Unit using (Unit; unit)

instance
  semigroupList : Semigroup (List A)
  semigroupList ._<>_ [] ys = ys
  semigroupList ._<>_ (x :: xs) ys = x :: xs <> ys

  monoidList : Monoid (List A)
  monoidList .mempty = []

  foldableList : Foldable List
  foldableList .foldMap f = \ where
    [] -> mempty
    (a :: as) -> f a <> foldMap f as

  functorList : Functor List
  functorList .map f [] = []
  functorList .map f (x :: xs) = f x :: map f xs

  applicativeList : Applicative List
  applicativeList .pure x = x :: []
  applicativeList ._<*>_ = \ where
    [] _ -> []
    _ [] -> []
    (f :: fs) (x :: xs) -> f x :: (fs <*> xs)

  alternativeList : Alternative List
  alternativeList .empty = mempty
  alternativeList ._<|>_ = _<>_

  monadList : Monad List
  monadList ._>>=_ = \ where
    [] k -> []
    (x :: xs) k -> k x <> (xs >>= k)

til : Nat -> List Nat
til 0 = []
til (suc n) = til n <> pure n

range : Nat -> Nat -> List Nat
range m n with compare m n
... | GT = []
... | EQ = pure n
... | LT = map (_+ m) $ til $ suc (n - m)

-- scanr is the right-to-left dual of scanl.
scanr : (A -> B -> B) -> B -> List A -> List B
scanr f b [] = b :: []
scanr f b (a :: as) with scanr f b as
... | [] = []
... | (x :: xs) = f a x :: x :: xs

-- scanl is similar to foldl, but returns a list of successive reduced values
-- from the left
scanl : (B -> A -> B) -> B -> List A -> List B
scanl f b [] = pure b
scanl f b (a :: as) = b :: scanl f (f b a) as

--------------------------------------------------------------------------------
-- Special folds
--------------------------------------------------------------------------------

-- Flattens a list of lists into a list.
concat : List (List A) -> List A
concat = join

-- Map a function over all the elements of a container and concatenate the
-- resulting lists.
concatMap : (A -> List B) -> List A -> List B
concatMap = _=<<_

-- and returns the conjunction of a container of Bools. For the result to be
-- true, the container must be finite; false, however, results from a false
-- value finitely far from the left end.
and : List Bool -> Bool
and [] = false
and (false :: bs) = false
and (true :: bs) = and bs

-- or returns the disjunction of a container of Bools. For the result to be
-- false, the container must be finite; true, however, results from a true
-- value finitely far from the left end.
or : List Bool -> Bool
or [] = true
or (true :: bs) = true
or (false :: bs) = or bs

-- Determines whether any element of the structure satisfies the predicate.
any : forall {A} -> (A -> Bool) -> List A -> Bool
any f as = or (map f as)

-- Determines whether all elements of the structure satisfy the predicate.
all : forall {A} -> (A -> Bool) -> List A -> Bool
all f as = and (map f as)

-- Returns the length of the given list.
length : forall {A} -> List A -> Nat
length = foldl (\ len _ -> len + 1) 0

--------------------------------------------------------------------------------
-- Searching lists
--------------------------------------------------------------------------------

-- filter, applied to a predicate and a list, returns the list of those
-- elements that satisfy the predicate.
filter : (A -> Bool) -> List A -> List A
filter p [] = []
filter p (a :: as) = if p a then a :: filter p as else as

-- The find function takes a predicate and a structure and returns the leftmost
-- element of the list matching the predicate, or nothing if there is no such
-- element.
find : (A -> Bool) -> List A -> Maybe A
find p as with filter p as
... | [] = nothing
... | (a :: _) = just a

-- The partition function takes a predicate, a list and returns the pair of
-- lists of elements which do and do not satisfy the predicate.
partition : (A -> Bool) -> List A -> Pair (List A) (List A)
partition p xs = foldr (select p) ([] , []) xs
  where
    select : (A -> Bool) -> A -> Pair (List A) (List A) -> Pair (List A) (List A)
    select p a (ts , fs) with p a
    ... | true = (a :: ts , fs)
    ... | false = (ts , a :: fs)

--------------------------------------------------------------------------------
-- Extracting sublists
--------------------------------------------------------------------------------

-- take n, applied to a list xs, returns the prefix of xs of length n, or xs
-- itself if n > length xs.
take : Nat -> List A -> List A
take 0 _ = []
take (suc n) [] = []
take (suc n) (x :: xs) = x :: take n xs

-- drop n xs returns the suffix of xs after the first n elements, or [] if
-- n > length xs.
drop : Nat -> List A -> List A
drop 0 as = as
drop (suc n) [] = []
drop (suc n) (_ :: as) = drop n as

-- The break function finds the longest initial segment of a list that does
-- not satisfy the given predicate and returns it paired with the remainder
-- of the list.
break : (A -> Bool) -> List A -> Pair (List A) (List A)
break p [] = ([] , [])
break p as@(x :: xs) =
  if p x then ([] , as)
  else let (ys , zs) = break p xs in (x :: ys , zs)

-- Splits a list into two pieces at the given index.
splitAt : Nat -> List A -> Pair (List A) (List A)
splitAt n as = (take n as , drop n as)

-- The stripPrefix function drops the given prefix from a list. It returns
-- nothing if the list did not start with the prefix given, or just the list
-- after the prefix, if it does.
stripPrefix : {{_ : Eq A}} -> List A -> List A -> Maybe (List A)
stripPrefix [] as = just as
stripPrefix (x :: xs) (y :: ys) =
  if x == y then stripPrefix xs ys else nothing
stripPrefix _ _ = nothing

-- The tails function returns all final segments of the argument, longest
-- first.
tails : List A -> List (List A)
tails [] = pure []
tails as@(x :: xs) = as :: tails xs

-- takeWhile, applied to a predicate p and a list as, returns the longest
-- prefix (possibly empty) of as of elements that satisfy p:
takeWhile : (A -> Bool) -> List A -> List A
takeWhile _ [] = []
takeWhile p (a :: as) with p a
... | true = a :: takeWhile p as
... | false = []

-- dropWhile p as returns the suffix remaining after 'takeWhile' p as:
dropWhile : (A -> Bool) -> List A -> List A
dropWhile _ [] = []
dropWhile p xs@(y :: ys) with p y
... | true = dropWhile p ys
... | false = ys

--------------------------------------------------------------------------------
-- "By" operations
--------------------------------------------------------------------------------

-- deleteBy eq x xs deletes the first item y in xs that satisfies eq x y.
--deleteBy : (A -> A -> Bool) -> A -> List A -> List A
--deleteBy _ _ [] = []
--deleteBy eq x (y :: ys) = if eq x y then ys else y :: deleteBy eq x ys

-- Removes duplicate elements from a list where the duplicates are determined
-- by the user-supplied equality predicate.
--nubBy : (A -> A -> Bool) -> List A -> List A
--nubBy {A} eq l = nubBy' l []
--  where
--    elemBy : (A -> A -> Bool) -> A -> List A -> Bool
--    elemBy _ _ [] = false
--    elemBy eq y (x :: xs) = eq x y || elemBy eq y xs
--
--    nubBy' : List A -> List A -> List A
--    nubBy' [] _ = []
--    nubBy' (y :: ys) xs =
--      if elemBy eq y xs
--      then nubBy' ys xs
--      else y :: nubBy' ys (y :: xs)

-- Construct the union of two lists. Duplicates are removed according to the
-- user-supplied equality predicate.
--unionBy : (A -> A -> Bool) -> List A -> List A -> List A
--unionBy eq xs ys = xs <> foldl (flip (deleteBy eq)) (nubBy eq ys) ys

--------------------------------------------------------------------------------
-- Set-like operations
--------------------------------------------------------------------------------

-- Deletes an element from a list.
--delete : {{_ : Eq A}} -> A -> List A -> List A
--delete = deleteBy _==_

-- The nub function removes duplicate elements from a list. In particular, it
-- keeps only the first occurrence of each element. (The name nub means
-- 'essence'.) It is a special case of nubBy, which allows the programmer to
-- supply their own equality test.
--nub : {{_ : Eq A}} -> List A -> List A
--nub = nubBy _==_

-- The union function returns the list union of the two lists. Duplicates, and
-- elements of the first list, are removed from the the second list, but if the
-- first list contains duplicates, so will the result. It is a special case of
-- unionBy, which allows the programmer to supply their own equality test.
--union : {{_ : Eq A}} -> List A -> List A -> List A
--union = unionBy _==_

--------------------------------------------------------------------------------
-- Zipping
--------------------------------------------------------------------------------

-- Zips two lists together with a function.
zipWith : (A -> B -> C) -> List A -> List B -> List C
zipWith f [] _ = []
zipWith f _ [] = []
zipWith f (x :: xs) (y :: ys) = f x y :: zipWith f xs ys

-- Zips two lists into a list of pairs.
zip : List A -> List B -> List (Pair A B)
zip = zipWith _,_

-- Zips together a list of heads and a list of tails.
--zipCons : List A -> List (List A) -> List (List A)
--zipCons heads tails =
--    (zipWith _::_ heads (tails <> padding)) <> excess
--  where
--    -- Extra tails that will be zipped with those heads that have no
--    -- corresponding tail in tails.
--    padding = replicate (length heads - length tails) []
--    -- The tails that cannot be zipped because they have no corresponding
--    -- head in heads.
--    excess = snd (splitAt (length heads) tails)

--------------------------------------------------------------------------------
-- Transformations
--------------------------------------------------------------------------------

-- Reverses a list.
reverse : List A -> List A
reverse = foldl (flip _::_) []

-- Transposes the elements of a list of lists (thought of as a matrix).
--transpose : List (List A) -> List (List A)
--transpose [] = []
--transpose (heads :: tails) = zipCons heads (transpose tails)

-- Traverse a list.
traverse : forall {F A B} {{_ : Applicative F}}
  -> (A -> F B) -> List A -> F (List B)
traverse f [] = pure []
traverse f (a :: as) = (| _::_ (f a) (traverse f as) |)

-- Traverse a list without accumulating.
traverse' : forall {F A B} {{_ : Applicative F}}
  -> (A -> F B) -> List A -> F Unit
traverse' f = foldr (_*>_ <<< f) (pure unit)

-- Shorthand for flip traverse'.
for' : forall {F A B} {{_ : Applicative F}}
  -> List A -> (A -> F B) -> F Unit
for' = flip traverse'

--------------------------------------------------------------------------------
-- Predicates
--------------------------------------------------------------------------------

-- Checks if a list is empty.
null : List A -> Bool
null [] = true
null _ = false

-- Takes two lists and returns true if the first list is a prefix of the
-- second.
isPrefixOf : {{_ : Eq A}} -> List A -> List A -> Bool
isPrefixOf [] _ = true
isPrefixOf _ [] = false
isPrefixOf (x :: xs) (y :: ys) = (x == y) && (isPrefixOf xs ys)

-- The isSuffixOf function takes two lists and returns true iff the first list
-- is a suffix of the second.
isSuffixOf : {{_ : Eq A}} -> List A -> List A -> Bool
isSuffixOf xs ys = isPrefixOf (reverse xs) (reverse ys)

-- The isInfixOf function takes two lists and returns true iff the first list
-- is contained, wholly and intact, anywhere within the second.
isInfixOf : {{_ : Eq A}} -> List A -> List A -> Bool
isInfixOf xs ys = any (isPrefixOf xs) (tails ys)

------------------------------------------------------------------------------
-- Indexing operations
------------------------------------------------------------------------------

-- indexed pairs each element with its index.
indexed : List A -> List (Pair Nat A)
indexed as = zip indices as
  where
    indices : List Nat
    indices = til (length as)

-- elemAt as n retrieves the (n - 1)th item in the list as.
elemAt : Nat -> List A -> Maybe A
elemAt _ [] = nothing
elemAt 0 (a :: _) = just a
elemAt (suc i) (_ :: as) = elemAt i as

-- deleteAt deletes the element at an index. If the index is invalid, the
-- original list will be returned.
deleteAt : Nat -> List A -> List A
deleteAt i xs with i < length xs
deleteAt 0 (y :: ys) | true = ys
deleteAt (suc n) (y :: ys) | true = y :: deleteAt n ys
deleteAt _ [] | true = [] -- This case should never be reached.
... | false = xs
