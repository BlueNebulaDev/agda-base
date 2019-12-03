{-# OPTIONS --type-in-type #-}

module Control.Monad.Writer where

-- Writer W X models computations of type X that store a value of type W. We
-- call such computations Writer computations.

open import Data.Product

Writer : Set -> Set -> Set
Writer W X = X * W

-- Writer W is a functor.

open import Control.Category
open import Data.Functor

instance
  Functor:Writer : {W : Set} -> Endofunctor Sets (Writer W)
  Functor:Writer .map f (x , w) = (f x , w)

-- The tell function will produce a Writer computation that just stores the
-- given value.

open import Control.Monad.Eff
open import Data.Either
open import Data.Functor.Union
open import Data.List.Base
open import Data.Unit

tell : forall {W Fs} {{_ : Member (Writer W) Fs}} -> W -> Eff Fs Unit
tell w = send (tt , w)

-- If W is a monoid, then Writer W is a monad. The return function in this case
-- produces a Writer computation that stores mempty. The bind operation
-- essentially does function application while combining the stored values
-- using the monoid operation.

open import Control.Monad
open import Data.Monoid

instance
  Monad:Writer : forall {W} {{_ : Monoid W}} -> Monad Sets (Writer W)
  Monad:Writer = record {
      instance:Functor = Functor:Writer;
      join = \ { ((x , w) , w') -> (x , w <> w') };
      return = \ x -> (x , mempty)
    }
