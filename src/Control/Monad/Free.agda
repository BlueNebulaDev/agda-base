{-# OPTIONS --type-in-type #-}

module Control.Monad.Free where

-- Let C be a category and let F : ob C -> ob C. A free monad on F is a monad
-- Free F on C equipped with a transformation lift : F ~> Free F satisfying
-- the following universal property: for any monad M on C and transformation
-- t : F ~> M, there is a unique monad morphism interpret t : Free F ~> M with
-- the property that t = interpret t <<< lift. When C = Sets, we define
-- Free F, lift and interpret as follows:

open import Control.Monad public

module Free where

  record Free (F : Set -> Set) (X : Set) : Set where
    constructor Free:
    field
      run : forall {M} {{_ : Monad Sets M}} -> (F ~> M) -> M X

  open Free

  lift : forall {F} -> F ~> Free F
  lift x = Free: \ t -> t x

  interpret : forall {F M} {{_ : Monad Sets M}} -> (F ~> M) -> Free F ~> M
  interpret t free = run free t

  -- This is the left inverse (retract) of lift.

  lower : forall {M} {{_ : Monad Sets M}} -> Free M ~> M
  lower = interpret id

  -- Free F is a functor.

  instance
    Functor:Free : forall {F} -> Endofunctor Sets (Free F)
    Functor:Free .map f free = Free: (map f <<< run free)

  -- Free F is a monad.

  instance
    Monad:Free : forall {F} -> Monad Sets (Free F)
    Monad:Free .return x = Free: \ _ -> return x
    Monad:Free .extend f m = Free: \ t ->
      join (map (interpret t <<< f) (interpret t m))

  -- Free forms a functor on the category Sets ^ Sets whose map operation is:

  hoist : forall {F G} -> (F ~> G) -> Free F ~> Free G
  hoist t free = interpret (lift <<< t) free

  -- Free also forms a monad on Sets ^ Sets. The return operation of this monad
  -- is lift; the extend operation is defined below:

  flatMap : forall {F G}
    -> (F ~> Free G) -> Free F ~> Free G
  flatMap = interpret

  -- Free is a free construction. It is basically the left-adjoint of the
  -- would-be forgetful functor U that forgets the monad structure of a functor.
  -- The right adjunct of this adjunction is basically interpret. The left
  -- adjunct is given below.

  uninterpret : forall {F M} -> (Free F ~> M) -> F ~> M
  uninterpret t x = t (lift x)

  -- When F is a functor, Free F X is an F-algebra for any type X. The operation
  -- of this algebra is:

  impure : forall {F X} -> F (Free F X) -> Free F X
  impure op = join (lift op)

  -- A fold operation based on the Kleisli triple definition of monad.

  fold : forall {F X Y}
    -> (X -> Y)
    -> (forall {X} -> (X -> Y) -> F X -> Y)
    -> Free F X -> Y
  fold {F} ret ext free = interpret t free ret ext
    where

      -- M is the free monad generated by F based on Church encoding of the
      -- Kleisli triple definition of monad.

      M : Set -> Set
      M X = forall {Y}
        -> (X -> Y)
        -> (forall {Z} -> (Z -> Y) -> F Z -> Y)
        -> Y

      instance
        Functor:M : Endofunctor Sets M
        Functor:M .map f m = \ ret ext -> m (f >>> ret) ext

        Monad:M : Monad Sets M
        Monad:M .return x = \ ret ext -> ret x
        Monad:M .extend f m = \ ret ext -> m (\ y -> (f y) ret ext) ext

      -- The lift operation of the free monad M.

      t : F ~> M
      t x = \ ret ext -> ext ret x

  -- A fold operation based on the standard definition of monad. This one
  -- requires F to be a functor.

  fold' : forall {F X Y} {{_ : Endofunctor Sets F}}
    -> (X -> Y)
    -> (F Y -> Y)
    -> Free F X -> Y
  fold' {F} {{inst}} ret jn free = interpret t free ret jn
    where

      -- M is the free monad generated by F based on Church encoding of the
      -- standard definition of monad.

      M : Set -> Set
      M X = forall {Y} -> (X -> Y) -> (F Y -> Y) -> Y

      instance
        Functor:M : Endofunctor Sets M
        Functor:M .map f m = \ ret jn -> m (f >>> ret) jn

        Monad:M : Monad Sets M
        Monad:M .return x = \ ret jn -> ret x
        Monad:M .extend f m = \ ret jn -> m (\ x -> (f x) ret jn) jn

      -- The lift operation of the free monad M.

      t : F ~> M
      t x = \ ret jn -> jn ((map {{inst}} ret) x)

open Free public
  hiding (module Free)
  using (Free; Free:; Monad:Free; Functor:Free)
