{-# OPTIONS --type-in-type #-}

module Data.BST.Naive where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Data.Foldable
open import Data.Traversable

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a : Set

-------------------------------------------------------------------------------
-- Tree
-------------------------------------------------------------------------------

data Tree (a : Set) : Set where
  Leaf : Tree a
  Node : Tree a -> a -> Tree a -> Tree a

instance
  Functor-Tree : Functor Tree
  Functor-Tree .map f t with t
  ... | Leaf = Leaf
  ... | Node l x r =  Node (map f l) (f x) (map f r)

  Foldable-Tree : Foldable Tree
  Foldable-Tree .foldMap f t with t
  ... | Leaf = mempty
  ... | Node l x r = foldMap f l <> f x <> foldMap f r

  Traversable-Tree : Traversable Tree
  Traversable-Tree .traverse f t with t
  ... | Leaf = pure Leaf
  ... | Node l x r = (| Node (traverse f l) (f x) (traverse f r) |)

  Eq-Tree : {{_ : Eq a}} -> Eq (Tree a)
  Eq-Tree ._==_ l r with l | r
  ... | Leaf | Leaf = True
  ... | Leaf | _ = False
  ... | _ | Leaf = False
  ... | Node u v w | Node x y z = v == y && u == x && w == z

  Show-Tree : {{_ : Show a}} -> Show (Tree a)
  Show-Tree .showsPrec _ Leaf = showString "Leaf"
  Show-Tree .showsPrec d (Node x y z) = showParen (d > appPrec)
    (showString "Node "
    <<< showsPrec appPrec+1 x
    <<< showString " "
    <<< showsPrec appPrec+1 y
    <<< showString " "
    <<< showsPrec appPrec+1 z)

-------------------------------------------------------------------------------
-- Basic operations
-------------------------------------------------------------------------------

module _ {{_ : Ord a}} where

  insert : a -> Tree a -> Tree a
  insert x Leaf = Node Leaf x Leaf
  insert x (Node l y r) with compare x y
  ... | EQ = Node l x r
  ... | LT = Node (insert x l) y r
  ... | GT = Node l y (insert x r)

  merge : Tree a -> Tree a -> Tree a
  merge Leaf t = t
  merge t Leaf = t
  merge t@(Node _ x _) s@(Node _ y _) =
    if x <= y
      then foldr insert s t
      else foldr insert t s

  delete : a -> Tree a -> Tree a
  delete _ Leaf = Leaf
  delete x (Node l y r) with compare x y
  ... | EQ = merge l r
  ... | LT = Node (delete x l) y r
  ... | GT = Node l y (delete x r)

  member : a -> Tree a -> Bool
  member x Leaf = False
  member x (Node l y r) with compare x y
  ... | EQ = True
  ... | LT = member x l
  ... | GT = member x r

  fromList : List a -> Tree a
  fromList = foldr insert Leaf
