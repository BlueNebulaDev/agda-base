{-# OPTIONS --type-in-type #-}

open import Prelude

open import Data.List as List using ()
open import Data.String as String using ()

reverseTest :
  List.reverse ('a' :: 'b' :: 'c' :: []) === 'c' :: 'b' :: 'a' :: []
reverseTest = refl

groupTest :
  List.group
    (String.unpack "Mississippi")
  ===
  map String.unpack
    ("M" :: "i" :: "ss" :: "i" :: "ss" :: "i" :: "pp" :: "i" :: [])
groupTest = refl
