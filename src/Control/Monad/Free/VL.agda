module Control.Monad.Free.VL where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a : Set
    m : Set -> Set
    f g : (Set -> Set) -> Set
    fs : List ((Set -> Set) -> Set)

-------------------------------------------------------------------------------
-- Effect / Effects
-------------------------------------------------------------------------------

Effect : Set
Effect = (Set -> Set) -> Set

infixr 4 _:<_
data Effects (m : Set -> Set) : List Effect -> Set where
  done : Effects m []
  _:<_ : f m -> Effects m fs -> Effects m (f :: fs)

-------------------------------------------------------------------------------
-- Elem
-------------------------------------------------------------------------------

record Elem (f : Effect) (fs : List Effect) : Set where
  field getElem : Effects m fs -> f m

open Elem {{...}} public

instance
  Elem-Base : Elem f (f :: fs)
  Elem-Base .getElem (f :< _) = f

  Elem-Rec : {{Elem f fs}} -> Elem f (g :: fs)
  Elem-Rec .getElem (_ :< effs) = getElem effs

-------------------------------------------------------------------------------
-- Free (van Laarhoven)
-------------------------------------------------------------------------------

record Free (fs : List Effect) (a : Set) : Set where
  constructor aFree
  field runFree : {{Monad m}} -> Effects m fs -> m a

open Free public

instance
  Functor-Free : Functor (Free fs)
  Functor-Free .map f program = aFree (map f <<< runFree program)

  Applicative-Free : Applicative (Free fs)
  Applicative-Free .pure x = aFree (const $ pure x)
  Applicative-Free ._<*>_ fs xs =
    aFree \ effects -> runFree fs effects <*> runFree xs effects

  Monad-Free : Monad (Free fs)
  Monad-Free ._>>=_ program k =
    aFree \ effects -> runFree program effects >>= \ x -> runFree (k x) effects

-- Because Elem-Implies and Elem-Obvious overlap, interpreting will not
-- work without Agda complaining.
interpret : {{Monad m}} -> Effects m fs -> Free fs a -> m a
interpret interpreter program = runFree program interpreter

liftFree : {{Elem f fs}} -> (forall {m} -> f m -> m a) -> Free fs a
liftFree getOp = aFree \ effects -> getOp (getElem effects)
