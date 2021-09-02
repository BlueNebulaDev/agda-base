{-# OPTIONS --type-in-type #-}

module Control.Monad.Maybe.Trans where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Control.Alternative
open import Control.Monad.IO.Class
open import Control.Monad.Trans.Class
open import Data.Foldable
open import Data.Traversable

-------------------------------------------------------------------------------
-- Re-exports
-------------------------------------------------------------------------------

open Control.Monad.Trans.Class public

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a b : Set
    m n : Set -> Set

-------------------------------------------------------------------------------
-- MaybeT
-------------------------------------------------------------------------------

record MaybeT (m : Set -> Set) (a : Set) : Set where
  constructor MaybeT:
  field runMaybeT : m (Maybe a)

open MaybeT public

mapMaybeT : (m (Maybe a) -> n (Maybe b)) -> MaybeT m a -> MaybeT n b
mapMaybeT f = MaybeT: <<< f <<< runMaybeT

hoistMaybeT : {{Applicative m}} -> Maybe b -> MaybeT m b
hoistMaybeT = MaybeT: <<< pure

instance
  Functor-MaybeT : {{Functor m}} -> Functor (MaybeT m)
  Functor-MaybeT .map f = MaybeT: <<< map (map f) <<< runMaybeT

  Foldable-MaybeT : {{Foldable m}} -> Foldable (MaybeT m)
  Foldable-MaybeT .foldr {a = a} {b = b} f z = foldr go z <<< runMaybeT
    where
      go : Maybe a -> b -> b
      go Nothing y = y
      go (Just x) y = f x y

  Traversable-MaybeT : {{Traversable m}} -> Traversable (MaybeT m)
  Traversable-MaybeT .traverse f m = MaybeT: <$> traverse (traverse f) (runMaybeT m)

  Applicative-MaybeT : {{Monad m}} -> Applicative (MaybeT m)
  Applicative-MaybeT .pure = MaybeT: <<< pure <<< pure
  Applicative-MaybeT ._<*>_ fs xs = MaybeT: do
    f <- runMaybeT fs
    x <- runMaybeT xs
    pure (f <*> x)

  Alternative-MaybeT : {{Monad m}} -> Alternative (MaybeT m)
  Alternative-MaybeT .empty = MaybeT: (pure Nothing)
  Alternative-MaybeT ._<|>_ l r = MaybeT: do
    x <- runMaybeT l
    case x of \ where
      Nothing -> runMaybeT r
      (Just _) -> pure x

  Monad-MaybeT : {{Monad m}} -> Monad (MaybeT m)
  Monad-MaybeT ._>>=_ m k = MaybeT: do
    x <- runMaybeT m
    case x of \ where
      Nothing -> pure Nothing
      (Just y) -> runMaybeT (k y)

  MonadTrans-MaybeT : MonadTrans MaybeT
  MonadTrans-MaybeT .lift = MaybeT: <<< map Just

  MonadIO-MaybeT : {{MonadIO m}} -> MonadIO (MaybeT m)
  MonadIO-MaybeT .liftIO = lift <<< liftIO