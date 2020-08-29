module Control.Monad.Free where

open import Prelude
  hiding (fold)

record Free (f : Set -> Set) (a : Set) : Set where
  constructor Free:
  field run : forall {m} {{_ : Monad m}} -> (f ~> m) -> m a

open Free

lift : forall {f} -> f ~> Free f
lift x = Free: \ t -> t x

interpret : forall {f m} {{_ : Monad m}} -> (f ~> m) -> Free f ~> m
interpret t free = run free t

lower : forall {m} {{_ : Monad m}} -> Free m ~> m
lower = interpret id

instance
  Functor-Free : forall {f} -> Functor (Free f)
  Functor-Free .map f free = Free: (map f <<< run free)

  Applicative-Free : forall {f} -> Applicative (Free f)
  Applicative-Free .pure x = Free: \ _ -> return x
  Applicative-Free ._<*>_ f x = Free: \ t -> run f t <*> run x t

  Monad-Free : forall {f} -> Monad (Free f)
  Monad-Free ._>>=_ m f = Free: \ t ->
    join (map (interpret t <<< f) (interpret t m))

-- Free forms a functor on the category Sets ^ Sets whose map operation is:
hoist : forall {f g} -> (f ~> g) -> Free f ~> Free g
hoist t free = interpret (lift <<< t) free

-- Free also forms a monad on Sets ^ Sets. The return operation of this monad
-- is lift; the extend operation is defined below:
flatMap : forall {f g} -> (f ~> Free g) -> Free f ~> Free g
flatMap = interpret

-- Free is a free construction. It is basically the left-adjoint of the
-- would-be forgetful functor U that forgets the monad structure of a functor.
-- The right adjunct of this adjunction is basically interpret. The left
-- adjunct is given below.
uninterpret : forall {f m} -> (Free f ~> m) -> f ~> m
uninterpret t x = t (lift x)

-- When F is a functor, Free F A is an F-algebra for any type A. The operation
-- of this algebra is:
impure : forall {f a} -> f (Free f a) -> Free f a
impure op = join (lift op)

-- A fold operation based on the Kleisli triple definition of monad.
fold : forall {f a b}
  -> (a -> b)
  -> (forall {a} -> (a -> b) -> f a -> b)
  -> Free f a -> b
fold {f} ret ext free = interpret t free ret ext
  where

    -- M is the free monad generated by F based on Church encoding of the
    -- Kleisli triple definition of monad.
    M : Set -> Set
    M a = forall {b}
      -> (a -> b)
      -> (forall {c} -> (c -> b) -> f c -> b)
      -> b

    instance
      Functor-M : Functor M
      Functor-M .map f m = \ ret ext -> m (ret <<< f) ext

      Applicative-M : Applicative M
      Applicative-M .pure x = \ ret ext -> ret x
      Applicative-M ._<*>_ f x = \ ret ext ->
        f (\ g -> x (ret <<< g) ext) ext

      Monad-M : Monad M
      Monad-M ._>>=_ m f = \ ret ext -> m (\ y -> (f y) ret ext) ext

    -- The lift operation of the free monad M.
    t : f ~> M
    t x = \ ret ext -> ext ret x

-- A fold operation based on the standard definition of monad. This one
-- requires F to be a functor.
fold' : forall {f a b} {{_ : Functor f}}
  -> (a -> b)
  -> (f b -> b)
  -> Free f a -> b
fold' {f} {{inst}} ret jn free = interpret t free ret jn
  where

    -- M is the free monad generated by F based on Church encoding of the
    -- standard definition of monad.
    M : Set -> Set
    M a = forall {b} -> (a -> b) -> (f b -> b) -> b

    instance
      Functor-M : Functor M
      Functor-M .map f m = \ ret jn -> m (ret <<< f) jn

      Applicative-M : Applicative M
      Applicative-M .pure x = \ ret jn -> ret x
      Applicative-M ._<*>_ f x = \ ret jn ->
        f (\ g -> x (ret <<< g) jn) jn

      Monad-M : Monad M
      Monad-M ._>>=_ m f = \ ret jn -> m (\ x -> (f x) ret jn) jn

    -- The lift operation of the free monad M.
    t : f ~> M
    t x = \ ret jn -> jn ((map {{inst}} ret) x)
