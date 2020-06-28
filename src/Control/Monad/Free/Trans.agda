{-# OPTIONS --type-in-type #-}

module Control.Monad.Free.Trans where

open import Prelude

open import Control.Monad.Base
open import Control.Monad.Free.Class
open import Control.Monad.Morph
open import Control.Monad.Trans.Class

private
  variable
    R : Set
    F M N : Set -> Set

record FreeT (F : Set -> Set) (M : Set -> Set) (A : Set) : Set where
  constructor freeT:
  field
    runFreeT : (A -> M R) -> (forall {X} -> F X -> (X -> M R) -> M R) -> M R

open FreeT

liftFreeT : F ~> FreeT F M
liftFreeT x = freeT: λ ret bnd -> bnd x ret

instance
  functorFreeT : Functor (FreeT F M)
  functorFreeT .map f (freeT: h) = freeT: λ ret bnd ->
    h (ret ∘ f) bnd

  applicativeFreeT : Applicative (FreeT F M)
  applicativeFreeT .pure x = freeT: λ ret _ -> ret x
  applicativeFreeT ._<*>_ (freeT: f) (freeT: x) = freeT: λ ret bnd ->
    f (λ g -> x (λ a -> ret (g a)) bnd) bnd

  monadFreeT : Monad (FreeT F M)
  monadFreeT ._>>=_ (freeT: m) k = freeT: λ ret bnd ->
    m (λ a -> runFreeT (k a) ret bnd) bnd

  mfunctorFreeT : MFunctor (FreeT F)
  mfunctorFreeT .hoist t (freeT: m) = freeT: λ ret bnd ->
    join ∘ t $ m (return ∘ ret) (λ x f -> return $ bnd x (join ∘ t ∘ f))

  monadTransFreeT : MonadTrans (FreeT F)
  monadTransFreeT .lift m = freeT: λ ret jn -> join ((map ret) m)
  monadTransFreeT .tmap f g (freeT: m) = freeT: λ ret bnd ->
    f (m (g ∘ ret) (λ x k -> g (bnd x (f ∘ k))))

  monadFreeFreeT : MonadFree F (FreeT F M)
  monadFreeFreeT .wrap x = freeT: λ ret bnd ->
    bnd x (λ f -> runFreeT f ret bnd)

  monadBaseReaderT : {{_ : Monad N}} {{_ : MonadBase M N}}
    -> MonadBase M (FreeT F N)
  monadBaseReaderT .liftBase m = lift (liftBase m)
