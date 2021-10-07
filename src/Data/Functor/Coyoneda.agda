{-# OPTIONS --type-in-type #-}

module Data.Functor.Coyoneda where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Control.Alternative
open import Control.Monad.Trans.Class
open import Data.Foldable
open import Data.Traversable

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a b : Set
    f g : Set -> Set

-------------------------------------------------------------------------------
-- Coyoneda
-------------------------------------------------------------------------------

-- This is the existensial version Yoneda f a.
data Coyoneda (f : Set -> Set) (a : Set) : Set where
  coyoneda : (b -> a) -> f b -> Coyoneda f a

-- The coYoneda lemma states that f a ~= Coyoneda f a. The isomorphsim
-- is witnessed by lower and lift.
lowerCoyoneda : {{Functor f}} -> Coyoneda f a -> f a
lowerCoyoneda (coyoneda f x) = map f x

liftCoyoneda : f a -> Coyoneda f a
liftCoyoneda = coyoneda id

-- It turns out that Coyoneda is a free construction, i.e. Coyoneda f is
-- the free functor generated by f. This is the right adjunct of the
-- corresponding free/forgetful adjunction.
interpretCoyoneda : {{Functor g}}
  -> (forall {a} -> f a -> g a) -> Coyoneda f b -> g b
interpretCoyoneda t (coyoneda f x) = map f (t x)

-- This is the left adjunct.
uninterpretCoyoneda : (forall {a} -> Coyoneda f a -> g a) -> f b -> g b
uninterpretCoyoneda t x = t (liftCoyoneda x)

instance
  Functor-Coyoneda : Functor (Coyoneda f)
  Functor-Coyoneda .map f (coyoneda g x) = coyoneda (f <<< g) x

  Applicative-Coyoneda : {{Applicative f}} -> Applicative (Coyoneda f)
  Applicative-Coyoneda .pure = liftCoyoneda <<< pure
  Applicative-Coyoneda ._<*>_ (coyoneda f x) (coyoneda g y) =
    liftCoyoneda $ (\ u v -> f u (g v)) <$> x <*> y

  Alternative-Coyoneda : {{Alternative f}} -> Alternative (Coyoneda f)
  Alternative-Coyoneda .azero = liftCoyoneda azero
  Alternative-Coyoneda ._<|>_ l r =
    liftCoyoneda $ lowerCoyoneda l <|> lowerCoyoneda r

  Monad-Coyoneda : {{Monad f}} -> Monad (Coyoneda f)
  Monad-Coyoneda ._>>=_ (coyoneda f v) k =
    liftCoyoneda $ v >>= f >>> k >>> lowerCoyoneda

  Foldable-Coyoneda : {{Foldable f}} -> Foldable (Coyoneda f)
  Foldable-Coyoneda .foldr f z (coyoneda k a) = foldr (\ x y -> f (k x) y) z a

  Traversable-Coyoneda : {{Traversable f}} -> Traversable (Coyoneda f)
  Traversable-Coyoneda .traverse f (coyoneda k a) =
    coyoneda id <$> traverse (f <<< k) a

  MonadTrans-Coyoneda : MonadTrans Coyoneda
  MonadTrans-Coyoneda .lift = liftCoyoneda
