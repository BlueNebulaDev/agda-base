{-# OPTIONS --type-in-type #-}

module Data.Bytes where

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude hiding (putStrLn)

open import Data.Word

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

private
  variable
    a : Set

-------------------------------------------------------------------------------
-- Bytes
-------------------------------------------------------------------------------

postulate
  Bytes : Set
  putStrLn : Bytes -> IO Unit

private
  postulate
    primPack : List Word8 -> Bytes
    primUnpack : Bytes -> List Word8
    primAppend : Bytes -> Bytes -> Bytes
    primEmpty : Bytes
    primSingleton : Word8 -> Bytes
    primFoldr : (Word8 -> a -> a) -> a -> Bytes -> a

instance
  Packed-Bytes-Word8 : Packed Bytes Word8
  Packed-Bytes-Word8 .pack = primPack
  Packed-Bytes-Word8 .unpack = primUnpack

  Semigroup-Bytes : Semigroup Bytes
  Semigroup-Bytes ._<>_ = primAppend

  Monoid-Bytes : Monoid Bytes
  Monoid-Bytes .neutral = primEmpty

  IsBuildable-Bytes-Word8 : IsBuildable Bytes Word8
  IsBuildable-Bytes-Word8 .singleton = primSingleton

  IsFoldable-Bytes-Word8 : IsFoldable Bytes Word8
  IsFoldable-Bytes-Word8 .foldMap f bs =
    primFoldr (\ w accum -> f w <> accum) neutral bs

-------------------------------------------------------------------------------
-- FFI
-------------------------------------------------------------------------------

{-# FOREIGN GHC import qualified Data.ByteString as BS #-}
{-# FOREIGN GHC import qualified Data.ByteString.Char8 as Char8 #-}
{-# FOREIGN GHC import Data.ByteString (ByteString) #-}
{-# COMPILE GHC Bytes = type ByteString #-}
{-# COMPILE GHC primPack = BS.pack #-}
{-# COMPILE GHC primUnpack = BS.unpack #-}
{-# COMPILE GHC primAppend = BS.append #-}
{-# COMPILE GHC primEmpty = BS.empty #-}
{-# COMPILE GHC primSingleton = BS.singleton #-}
{-# COMPILE GHC primFoldr = BS.foldr #-}
{-# COMPILE GHC putStrLn = Char8.putStrLn #-}