{-# OPTIONS --type-in-type #-}

module Control.Monad.Writer where

open import Prelude

open import Control.Monad.Writer.Trans

open Control.Monad.Writer.Trans public
  using (functorWriterT; applicativeWriterT; monadWriterT)

private variable A B W W' : Set

Writer : Set -> Set -> Set
Writer W = WriterT W Identity

writer: : A * W -> Writer W A
writer: = writerT: ∘ identity:

runWriter : Writer W A -> A * W
runWriter = runIdentity ∘ runWriterT

execWriter : Writer W A -> W
execWriter m = snd (runWriter m)

mapWriter : (A * W -> B * W') -> Writer W A -> Writer W' B
mapWriter = mapWriterT ∘ map
