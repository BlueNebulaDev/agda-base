module Control.Monad.Iter.Trans where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Control.Exception
open import Control.Monad.Free.Class
open import Control.Monad.IO.Class
open import Control.Monad.Reader.Class
open import Control.Monad.State.Class
open import Control.Monad.Trans.Class
open import Control.Monad.Writer.Class
open import Data.Bifunctor
open import Data.Functor.Identity

-------------------------------------------------------------------------------
-- Re-exports
-------------------------------------------------------------------------------

open Control.Monad.Trans.Class public

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a b e r s w : Set
    m n : Set -> Set

-------------------------------------------------------------------------------
-- IterT
-------------------------------------------------------------------------------

record IterT (m : Set -> Set) (a : Set) : Set where
  constructor asIterT
  field runIterT : m (Either a (IterT m a))

open IterT public

delay : {{Monad m}} -> IterT m a -> IterT m a
delay iter .runIterT = pure (right iter)

never : {{Monad m}} -> IterT m a
never = asIterT $ pure (right never)

-- N.B. This should only be called if you're sure that the IterT m a value
-- terminates. If it doesn't terminate, this will loop forever.
execIterT : {{Monad m}} -> IterT m a -> m a
execIterT iter = runIterT iter >>= either pure execIterT

-- Safer version of execIterT' that stops after n steps.
execIterT' : {{Monad m}} -> Nat -> IterT m a -> m (Maybe a)
execIterT' 0 _ = pure nothing
execIterT' (suc n) iter = do
  res <- runIterT iter
  case res of \ where
    (left x) -> pure (just x)
    (right iter') -> execIterT' n iter'

hoistIterT : {{Monad n}}
  -> (forall {a} -> m a -> n a)
  -> IterT m a
  -> IterT n a
hoistIterT t iter = asIterT ((map $ hoistIterT t) <$> (t $ runIterT iter))

instance
  Functor-IterT : {{Monad m}} -> Functor (IterT m)
  Functor-IterT .map f iter =
    asIterT $ map (either (left <<< f) (right <<< map f)) (runIterT iter)

  Applicative-IterT : {{Monad m}} -> Applicative (IterT m)
  Applicative-IterT .pure x = asIterT $ pure (left x)
  Applicative-IterT ._<*>_ iter x = asIterT do
    res <- runIterT iter
    case res of \ where
      (left f) -> runIterT (map f x)
      (right iter') -> pure (right (iter' <*> x))

  Monad-IterT : {{Monad m}} -> Monad (IterT m)
  Monad-IterT ._>>=_ iter k = asIterT do
    res <- runIterT iter
    case res of \ where
      (left m) -> runIterT (k m)
      (right iter') -> pure (right (iter' >>= k))

  Alternative-IterT : {{Monad m}} -> Alternative (IterT m)
  Alternative-IterT .azero = never
  Alternative-IterT ._<|>_ l r = asIterT do
    resl <- runIterT l
    case resl of \ where
      (left _) -> pure resl
      (right l') -> do
        resr <- runIterT r
        case resr of \ where
          (left _) -> pure resr
          (right r') -> pure $ right (l' <|> r')

  MonadFree-IterT : {{Monad m}} -> MonadFree Identity (IterT m)
  MonadFree-IterT .wrap (asIdentity iter) = delay iter

  MonadTrans-IterT : MonadTrans IterT
  MonadTrans-IterT .lift m .runIterT = map left m

  MonadReader-IterT : {{MonadReader r m}} -> MonadReader r (IterT m)
  MonadReader-IterT .ask = lift ask
  MonadReader-IterT .local f = hoistIterT (local f)

  MonadWriter-IterT : {{MonadWriter w m}} -> MonadWriter w (IterT m)
  MonadWriter-IterT .tell = lift <<< tell
  MonadWriter-IterT {w = w} {m = m} .listen {a = a} iter =
      asIterT $ map concat' $ listen (map listen <$> runIterT iter)
    where
      c : Set
      c = Pair w a

      concat' : Pair w (Either a (IterT m c)) -> Either c (IterT m c)
      concat' (w , left x) = left (w , x)
      concat' (w , right y) = right $ lmap (w <>_) <$> y

  MonadWriter-IterT {w = w} {m = m} .pass {a = a} iter .runIterT =
      pass' $ runIterT $ hoistIterT clean $ listen iter
    where
      clean : forall {a} -> m a -> m a
      clean = pass <<< map (const mempty ,_)

      c : Set
      c = Pair w (Pair (w -> w) a)

      g : (Either c (IterT m c)) -> m (Either a (IterT m a))
      g (left (w , (f , x))) = tell (f w) >> pure (left x)
      g (right iter') =
          pure (right (asIterT $ (join <<< map g) (runIterT iter')))

      pass' : m (Either c (IterT m c)) -> m (Either a (IterT m a))
      pass' = join <<< map g

  MonadState-IterT : {{MonadState s m}} -> MonadState s (IterT m)
  MonadState-IterT .state m = lift (state m)

  MonadIO-IterT : {{MonadIO m}} -> MonadIO (IterT m)
  MonadIO-IterT .liftIO = lift <<< liftIO

  MonadThrow-IterT : {{MonadThrow m}} -> MonadThrow (IterT m)
  MonadThrow-IterT .throw = lift <<< throw

  MonadCatch-IterT : {{MonadCatch m}} -> MonadCatch (IterT m)
  MonadCatch-IterT ._catch_ iter f = asIterT $
      (map (_catch f) <$> runIterT iter) catch (runIterT <<< f)
