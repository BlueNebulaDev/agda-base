{-# OPTIONS --type-in-type #-}

module Control.Monad.Reader.Trans where

open import Prelude

open import Control.Monad.Reader.Class
open import Control.Monad.Trans.Class

private
  variable
    A B R R' : Set
    M N : Set -> Set

record ReaderT (R : Set) (M : Set -> Set) (A : Set) : Set where
  constructor aReaderT
  field runReaderT : R -> M A

open ReaderT public

mapReaderT : (M A -> N B) -> ReaderT R M A -> ReaderT R N B
mapReaderT f m = aReaderT (f ∘ runReaderT m)

withReaderT : (R' -> R) -> ReaderT R M ~> ReaderT R' M
withReaderT f m = aReaderT (runReaderT m ∘ f)

instance
  functorReaderT : {{_ : Functor M}} -> Functor (ReaderT R M)
  functorReaderT .map f = mapReaderT (map f)

  applicativeReaderT : {{_ : Applicative M}} -> Applicative (ReaderT R M)
  applicativeReaderT .pure = aReaderT ∘ const ∘ pure
  applicativeReaderT ._<*>_ f v = aReaderT λ r ->
    runReaderT f r <*> runReaderT v r

  monadReaderT : {{_ : Monad M}} -> Monad (ReaderT R M)
  monadReaderT ._>>=_ m k = aReaderT λ r -> do
    a <- runReaderT m r
    runReaderT (k a) r

  monadReaderReaderT : {{_ : Monad M}} -> MonadReader R (ReaderT R M)
  monadReaderReaderT .ask = aReaderT return
  monadReaderReaderT .local f = withReaderT f

  monadTransReaderT : MonadTrans (ReaderT R)
  monadTransReaderT .lift = aReaderT ∘ const
  monadTransReaderT .transform = monadReaderT