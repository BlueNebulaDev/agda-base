module Data.Functor.Coyoneda where

open import Prelude

private
  variable
    a b : Set
    f g : Set -> Set

-- This is the existensial version Yoneda F A.
data Coyoneda (f : Set -> Set) (b : Set) : Set where
  Coyoneda: : f a -> (a -> b) -> Coyoneda f b

-- Coyoneda C F is a functor.
instance
  Functor-Coyoneda : Functor (Coyoneda f)
  Functor-Coyoneda .map f (Coyoneda: x g) = Coyoneda: x (f <<< g)

-- The coYoneda lemma states that F B ~= Coyoneda C F Y. The isomorphsim
-- is witnessed by lower and lift.
lower : {{_ : Functor f}} -> Coyoneda f a -> f a
lower (Coyoneda: x f) = map f x

lift : f a -> Coyoneda f a
lift y = Coyoneda: y id

-- It turns out that Coyoneda is a free construction, i.e. Coyoneda C F is
-- the free functor generated by F. This is the right adjunct of the
-- corresponding free/forgetful adjunction.
interpret : {{_ : Functor g}} -> (f ~> g) -> Coyoneda f ~> g
interpret t (Coyoneda: x f) = map f (t x)

-- This is the left adjunct.
uninterpret :  (Coyoneda f ~> g) -> f ~> g
uninterpret t x = t (lift x)
