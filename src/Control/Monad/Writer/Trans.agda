{-# OPTIONS --type-in-type #-}

module Control.Monad.Writer.Trans where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Control.Alternative
open import Control.Exception
open import Control.Monad.Cont.Class
open import Control.Monad.IO.Class
open import Control.Monad.Reader.Class
open import Control.Monad.State.Class
open import Control.Monad.Trans.Class
open import Control.Monad.Writer.Class

-------------------------------------------------------------------------------
-- Re-exports
-------------------------------------------------------------------------------

open Control.Monad.Trans.Class public
open Control.Monad.Writer.Class public

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a b e r s w w' : Type
    m n : Type -> Type

-------------------------------------------------------------------------------
-- WriterT
-------------------------------------------------------------------------------

abstract
  WriterT : (w : Type) (m : Type -> Type) (a : Type) -> Type
  WriterT w m a = m (w * a)

  runWriterT : WriterT w m a -> m (w * a)
  runWriterT = id

  mkWriterT : m (w * a) -> WriterT w m a
  mkWriterT = id

execWriterT : {{Functor m}} -> WriterT w m a -> m w
execWriterT = map fst <<< runWriterT

mapWriterT : (m (w * a) -> n (w' * b))
  -> WriterT w m a -> WriterT w' n b
mapWriterT f = mkWriterT <<< f <<< runWriterT

instance
  Functor-WriterT : {{Functor m}} -> Functor (WriterT w m)
  Functor-WriterT .map = mapWriterT <<< map <<< map

  Applicative-WriterT : {{Monoid w}} -> {{Applicative m}}
    -> Applicative (WriterT w m)
  Applicative-WriterT .pure = mkWriterT <<< pure <<< (neutral ,_)
  Applicative-WriterT ._<*>_ fs xs =
      mkWriterT (| k (runWriterT fs) (runWriterT xs) |)
    where
      k : _
      k (w , f) (w' , x) = (w <> w' , f x)

  Alternative-WriterT : {{Monoid w}} -> {{Alternative m}}
    -> Alternative (WriterT w m)
  Alternative-WriterT .empty = mkWriterT empty
  Alternative-WriterT ._<|>_ l r = mkWriterT (runWriterT l <|> runWriterT r)

  Monad-WriterT : {{Monoid w}} -> {{Monad m}} -> Monad (WriterT w m)
  Monad-WriterT ._>>=_ m k = mkWriterT do
    (w , x) <- runWriterT m
    (w' , y) <- runWriterT (k x)
    pure (w <> w' , y)

  MonadTrans-WriterT : {{Monoid w}} -> MonadTrans (WriterT w)
  MonadTrans-WriterT .lift m = mkWriterT do
    x <- m
    pure (neutral , x)

  MonadWriter-WriterT : {{Monoid w}} -> {{Monad m}}
    -> MonadWriter w (WriterT w m)
  MonadWriter-WriterT .tell = mkWriterT <<< pure <<< (_, unit)
  MonadWriter-WriterT .listen m = mkWriterT do
    (w , x) <- runWriterT m
    pure (w , (w , x))
  MonadWriter-WriterT .pass m = mkWriterT do
    (w , (f , x)) <- runWriterT m
    pure (f w , x)

  MonadReader-WriterT : {{Monoid w}} -> {{MonadReader r m}}
    -> MonadReader r (WriterT w m)
  MonadReader-WriterT .ask = lift ask
  MonadReader-WriterT .local = mapWriterT <<< local

  MonadState-WriterT : {{Monoid w}} -> {{MonadState s m}}
    -> MonadState s (WriterT w m)
  MonadState-WriterT .state = lift <<< state

  MonadThrow-WriterT : {{Monoid w}} -> {{MonadThrow m}}
    -> MonadThrow (WriterT w m)
  MonadThrow-WriterT .throw = lift <<< throw

  MonadCatch-WriterT : {{Monoid w}} -> {{MonadCatch m}}
    -> MonadCatch (WriterT w m)
  MonadCatch-WriterT .catch m h = mkWriterT $
    catch (runWriterT m) (runWriterT <<< h)

  MonadCont-WriterT : {{Monoid w}} -> {{MonadCont m}}
    -> MonadCont (WriterT w m)
  MonadCont-WriterT .callCC f = mkWriterT $
    callCC \ c -> (runWriterT <<< f) (mkWriterT <<< c <<< (neutral ,_))
