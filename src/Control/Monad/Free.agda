{-# OPTIONS --type-in-type #-}

module Control.Monad.Free where

open import Prelude
  hiding (fold)

-- Let C be a category and let F : ob C -> ob C. A free monad on F is a monad
-- Free F on C equipped with a transformation lift : F ~> Free F satisfying
-- the following universal property: for any monad M on C and transformation
-- t : F ~> M, there is a unique monad morphism interpret t : Free F ~> M with
-- the property that t = interpret t ∘ lift. When C = Sets, we define
-- Free F, lift and interpret as follows:
record Free (F : Set -> Set) (A : Set) : Set where
  constructor Free:
  field
    run : ∀ {M} {{_ : Monad M}} -> (F ~> M) -> M A

open Free

lift : ∀ {F} -> F ~> Free F
lift x = Free: λ t -> t x

interpret : ∀ {F M} {{_ : Monad M}} -> (F ~> M) -> Free F ~> M
interpret t free = run free t

-- This is the left inverse (retract) of lift.
lower : ∀ {M} {{_ : Monad M}} -> Free M ~> M
lower = interpret id

instance
  functorFree : ∀ {F} -> Functor (Free F)
  functorFree .map f free = Free: (map f ∘ run free)

  applicativeFree : ∀ {F} -> Applicative (Free F)
  applicativeFree .pure x = Free: λ _ -> return x
  applicativeFree ._<*>_ f x = Free: λ t -> run f t <*> run x t

  monadFree : ∀ {F} -> Monad (Free F)
  monadFree ._>>=_ m f = Free: λ t ->
    join (map (interpret t ∘ f) (interpret t m))

-- Free forms a functor on the category Sets ^ Sets whose map operation is:
hoist : ∀ {F G} -> (F ~> G) -> Free F ~> Free G
hoist t free = interpret (lift ∘ t) free

-- Free also forms a monad on Sets ^ Sets. The return operation of this monad
-- is lift; the extend operation is defined below:
flatMap : ∀ {F G} -> (F ~> Free G) -> Free F ~> Free G
flatMap = interpret

-- Free is a free construction. It is basically the left-adjoint of the
-- would-be forgetful functor U that forgets the monad structure of a functor.
-- The right adjunct of this adjunction is basically interpret. The left
-- adjunct is given below.
uninterpret : ∀ {F M} -> (Free F ~> M) -> F ~> M
uninterpret t x = t (lift x)

-- When F is a functor, Free F A is an F-algebra for any type A. The operation
-- of this algebra is:
impure : ∀ {F A} -> F (Free F A) -> Free F A
impure op = join (lift op)

-- A fold operation based on the Kleisli triple definition of monad.
fold : ∀ {F A B}
  -> (A -> B)
  -> (∀ {A} -> (A -> B) -> F A -> B)
  -> Free F A -> B
fold {F} ret ext free = interpret t free ret ext
  where

    -- M is the free monad generated by F based on Church encoding of the
    -- Kleisli triple definition of monad.
    M : Set -> Set
    M A = ∀ {B}
      -> (A -> B)
      -> (∀ {C} -> (C -> B) -> F C -> B)
      -> B

    instance
      functorM : Functor M
      functorM .map f m = λ ret ext -> m (ret ∘ f) ext

      applicativeM : Applicative M
      applicativeM .pure x = λ ret ext -> ret x
      applicativeM ._<*>_ f x = λ ret ext ->
        f (λ g -> x (ret ∘ g) ext) ext

      monadM : Monad M
      monadM ._>>=_ m f = λ ret ext -> m (λ y -> (f y) ret ext) ext

    -- The lift operation of the free monad M.
    t : F ~> M
    t x = λ ret ext -> ext ret x

-- A fold operation based on the standard definition of monad. This one
-- requires F to be a functor.
fold' : ∀ {F A B} {{_ : Functor F}}
  -> (A -> B)
  -> (F B -> B)
  -> Free F A -> B
fold' {F} {{inst}} ret jn free = interpret t free ret jn
  where

    -- M is the free monad generated by F based on Church encoding of the
    -- standard definition of monad.
    M : Set -> Set
    M A = ∀ {B} -> (A -> B) -> (F B -> B) -> B

    instance
      functorM : Functor M
      functorM .map f m = λ ret jn -> m (ret ∘ f) jn

      applicativeM : Applicative M
      applicativeM .pure x = λ ret jn -> ret x
      applicativeM ._<*>_ f x = λ ret jn ->
        f (λ g -> x (ret ∘ g) jn) jn

      monadM : Monad M
      monadM ._>>=_ m f = λ ret jn -> m (λ x -> (f x) ret jn) jn

    -- The lift operation of the free monad M.
    t : F ~> M
    t x = λ ret jn -> jn ((map {{inst}} ret) x)
