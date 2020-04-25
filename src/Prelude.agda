{-# OPTIONS --type-in-type #-}

module Prelude where

private
  variable
    A B C D S : Set
    F M : Set -> Set

--------------------------------------------------------------------------------
-- Primitive types and type constructors
--------------------------------------------------------------------------------

data Void : Set where

open import Agda.Builtin.Unit public
  renaming (⊤ to Unit; tt to unit)

open import Agda.Builtin.Bool public
  using (Bool; true; false)

open import Agda.Builtin.Nat public
  using (Nat; suc)

open import Agda.Builtin.Int public
  using (Int; pos; negsuc)

open import Agda.Builtin.Float public
  using (Float)

open import Agda.Builtin.Char public
  using (Char)

open import Agda.Builtin.String public
  using (String)

Not : Set -> Set
Not A = A -> Void

open import Agda.Builtin.Equality public
  using (refl)
  renaming (_≡_ to _===_)

Function : Set -> Set -> Set
Function A B = A -> B

data Either (A B : Set) : Set where
  left : A -> Either A B
  right : B -> Either A B

open import Agda.Builtin.Sigma public
  renaming (Σ to Sigma)

Pair : Set -> Set -> Set
Pair A B = Sigma A (λ _ -> B)

data Maybe (A : Set) : Set where
  nothing : Maybe A
  just : A -> Maybe A

open import Agda.Builtin.List public
  using (List; [])
  renaming (_∷_ to _::_)

open import Agda.Builtin.IO public
  using (IO)

--------------------------------------------------------------------------------
-- Wrappers
--------------------------------------------------------------------------------

record Identity (A : Set) : Set where
  constructor anIdentity
  field runIdentity : A

open Identity public

record Const (A B : Set) : Set where
  constructor aConst
  field getConst : A

open Const public

-- For additive semigroups, monoids, etc.
record Sum (A : Set) : Set where
  constructor aSum
  field getSum : A

open Sum public

-- For multiplicative semigroups, monoids, etc.
record Product (A : Set) : Set where
  constructor aProduct
  field getProduct : A

open Product public

-- For dual semigroups, orders, etc.
record Dual (A : Set) : Set where
  constructor aDual
  field getDual : A

open Dual public

-- Semigroup where x <> y = x
record First (A : Set) : Set where
  constructor aFirst
  field getFirst : A

open First public

-- Semigroup where x <> y = y
record Last (A : Set) : Set where
  constructor aLast
  field getLast : A

open Last public

-- For semigroups, monoids, etc. where x <> y = min x y
record Min (A : Set) : Set where
  constructor aMin
  field getMin : A

open Min public

-- For Semigroups, monoids, etc. where x <> y = max x y
record Max (A : Set) : Set where
  constructor aMax
  field getMax : A

open Max public

-- Bool semigroup where x <> y = x || y.
record Any : Set where
  constructor anAny
  field getAny : Bool

-- Bool semigroup where x <> y = x && y.
record All : Set where
  constructor anAll
  field getAll : Bool

open All public

open Any public

-- Endofunctions
record Endo A : Set where
  constructor anEndo
  field appEndo : A -> A

open Endo public

--------------------------------------------------------------------------------
-- Primitive functions and operations
--------------------------------------------------------------------------------

open import Agda.Builtin.TrustMe public
  renaming (primTrustMe to trustMe)

id : A -> A
id a = a

const : A -> B -> A
const a _ = a

flip : (A -> B -> C) -> B -> A -> C
flip f b a = f a b

infixr 0 _$_
_$_ : (A -> B) -> A -> B
_$_ = id

case_of_ : A -> (A -> B) -> B
case_of_ = flip _$_

infixr 9 _∘_
_∘_ : (B -> C) -> (A -> B) -> A -> C
g ∘ f = λ a -> g (f a)

infixr 10 if_then_else_
if_then_else_ : Bool -> A -> A -> A
if true then a else _ = a
if false then _ else a = a

natrec : A -> (Nat -> A -> A) -> Nat -> A
natrec a _ 0 = a
natrec a h n@(suc n-1) = h n-1 (natrec a h n-1)

applyN : (A -> A) -> Nat -> A -> A
applyN f n a = natrec a (const f) n

monus : Nat -> Nat -> Nat
monus = Agda.Builtin.Nat._-_

pred : Nat -> Nat
pred 0 = 0
pred (suc n) = n

foldZ : (Nat -> A) -> (Nat -> A) -> Int -> A
foldZ f g (pos n) = f n
foldZ f g (negsuc n) = g n

neg : Nat -> Int
neg 0 = pos 0
neg (suc n) = negsuc n

Nonneg : Int -> Set
Nonneg (pos _) = Unit
Nonneg _ = Void

nonneg : (n : Int) {_ : Nonneg n} -> Nat
nonneg (pos n) = n

private sub : Nat -> Nat -> Int
sub m 0 = pos m
sub 0 (suc n) = negsuc n
sub (suc m) (suc n) = sub m n

open Agda.Builtin.Float public
  renaming (
    primNatToFloat to natToFloat;
    primFloatSqrt to sqrt;
    primRound to round;
    primFloor to floor;
    primCeiling to ceil;
    primExp to exp;
    primLog to log;
    primSin to sin;
    primCos to cos;
    primTan to tan;
    primASin to asin;
    primACos to acos;
    primATan to atan;
    primATan2 to atan2
  )

open Agda.Builtin.Char public
  renaming (
    primIsLower to isLower;
    primIsDigit to isDigit;
    primIsAlpha to isAlpha;
    primIsSpace to isSpace;
    primIsAscii to isAscii;
    primIsLatin1 to isLatin1;
    primIsPrint to isPrint;
    primIsHexDigit to isHexDigit;
    primToUpper to toUpper;
    primToLower to toLower;
    primCharToNat to ord;
    primNatToChar to chr
  )

open Agda.Builtin.String public
  renaming (
    primStringToList to unpack;
    primStringFromList to pack
  )

either : (A -> C) -> (B -> C) -> Either A B -> C
either f g (left a) = f a
either f g (right b) = g b

mirror : Either A B -> Either B A
mirror = either right left

untag : Either A A -> A
untag = either id id

isLeft : Either A B -> Bool
isLeft (left _) = true
isLeft _ = false

isRight : Either A B -> Bool
isRight (left _) = false
isRight _ = true

fromLeft : A -> Either A B -> A
fromLeft a = either id (const a)

fromRight : B -> Either A B -> B
fromRight b = either (const b) id

fromEither : (A -> B) -> Either A B -> B
fromEither f = either f id

split : (A -> B) -> (A -> C) -> A -> Pair B C
split f g a = (f a , g a)

swap : Pair A B -> Pair B A
swap = split snd fst

dupe : A -> Pair A A
dupe = split id id

uncurry : (A -> B -> C) -> Pair A B -> C
uncurry f (a , b) = f a b

curry : (Pair A B -> C) -> A -> B -> C
curry f a b = f (a , b)

apply : Pair (A -> B) A -> B
apply = uncurry _$_

isJust : Maybe A -> Bool
isJust (just _) = true
isJust _ = false

isNothing : Maybe A -> Bool
isNothing (just _) = false
isNothing _ = true

maybe : B -> (A -> B) -> Maybe A -> B
maybe b f nothing = b
maybe b f (just a) = f a

fromMaybe : A -> Maybe A -> A
fromMaybe = flip maybe id

maybeToLeft : B -> Maybe A -> Either A B
maybeToLeft b = maybe (right b) left

maybeToRight : B -> Maybe A -> Either B A
maybeToRight b = mirror ∘ maybeToLeft b

leftToMaybe : Either A B -> Maybe A
leftToMaybe = either just (const nothing)

rightToMaybe : Either A B -> Maybe B
rightToMaybe = leftToMaybe ∘ mirror

ensure : (A -> Bool) -> A -> Maybe A
ensure p a = if p a then just a else nothing

listrec : B -> (A -> List A -> B -> B) -> List A -> B
listrec b f [] = b
listrec b f (a :: as) = f a as (listrec b f as)

maybeToList : Maybe A -> List A
maybeToList nothing = []
maybeToList (just a) = a :: []

listToMaybe : List A -> Maybe A
listToMaybe [] = nothing
listToMaybe (a :: _) = just a

private
  postulate
    mapIO : (A -> B) -> IO A -> IO B
    pureIO : A -> IO A
    apIO : IO (A -> B) -> IO A -> IO B
    bindIO : IO A -> (A -> IO B) -> IO B

postulate
  putStr : String -> IO Unit
  putStrLn : String -> IO Unit
  getLine : IO String
  getContents : IO String

{-# FOREIGN GHC import qualified Data.Text.IO as Text #-}
{-# COMPILE GHC mapIO = λ _ _ f io -> fmap f io #-}
{-# COMPILE GHC pureIO = λ _ a -> pure a #-}
{-# COMPILE GHC apIO = λ _ _ f x -> f <*> x #-}
{-# COMPILE GHC bindIO = λ _ _ io f -> io >>= f #-}
{-# COMPILE GHC putStr = Text.putStr #-}
{-# COMPILE GHC putStrLn = Text.putStrLn #-}
{-# COMPILE GHC getLine = Text.getLine #-}
{-# COMPILE GHC getContents = Text.getContents #-}

--------------------------------------------------------------------------------
-- BooleanAlgebra
--------------------------------------------------------------------------------

record BooleanAlgebra (B : Set) : Set where
  infixr 2 _||_
  infixr 3 _&&_
  field
    ff : B
    tt : B
    not : B -> B
    _||_ : B -> B -> B
    _&&_ : B -> B -> B

open BooleanAlgebra {{...}} public

instance
  booleanAlgebraBool : BooleanAlgebra Bool
  booleanAlgebraBool .ff = false
  booleanAlgebraBool .tt = true
  booleanAlgebraBool .not = λ where
    false -> true
    true -> false
  booleanAlgebraBool ._||_ = λ where
    false b -> b
    true _ -> true
  booleanAlgebraBool ._&&_ = λ where
    false _ -> false
    true b -> b

  booleanAlgebraFunction : {{_ : BooleanAlgebra B}} -> BooleanAlgebra (A -> B)
  booleanAlgebraFunction .ff = const ff
  booleanAlgebraFunction .tt = const tt
  booleanAlgebraFunction .not f = not ∘ f
  booleanAlgebraFunction ._||_ f g a = f a || g a
  booleanAlgebraFunction ._&&_ f g a = f a && g a

--------------------------------------------------------------------------------
-- Eq
--------------------------------------------------------------------------------

record Eq (A : Set) : Set where
  infix 4 _==_
  field _==_ : A -> A -> Bool

  infix 4 _/=_
  _/=_ : A -> A -> Bool
  a /= a' = if a == a' then false else true

open Eq {{...}} public

instance
  eqVoid : Eq Void
  eqVoid ._==_ = λ ()

  eqUnit : Eq Unit
  eqUnit ._==_ unit unit = true

  eqBool : Eq Bool
  eqBool ._==_ = λ where
    true true -> true
    false false -> false
    _ _ -> false

  eqNat : Eq Nat
  eqNat ._==_ = Agda.Builtin.Nat._==_

  eqInt : Eq Int
  eqInt ._==_ = λ where
    (pos m) (pos n) -> m == n
    (negsuc m) (negsuc n) -> m == n
    _ _ -> false

  eqFloat : Eq Float
  eqFloat ._==_ = Agda.Builtin.Float.primFloatNumericalEquality

  eqChar : Eq Char
  eqChar ._==_ = Agda.Builtin.Char.primCharEquality

  eqString : Eq String
  eqString ._==_ = Agda.Builtin.String.primStringEquality

  eqEither : {{_ : Eq A}} {{_ : Eq B}} -> Eq (Either A B)
  eqEither ._==_ = λ where
    (left a) (left a') -> a == a'
    (right b) (right b') -> b == b'
    _ _ -> false

  eqPair : {{_ : Eq A}} {{_ : Eq B}} -> Eq (Pair A B)
  eqPair ._==_ (a , b) (a' , b') = (a == a') && (b == b')

  eqMaybe : {{_ : Eq A}} -> Eq (Maybe A)
  eqMaybe ._==_ = λ where
    nothing nothing -> true
    (just a) (just a') -> a == a'
    _ _ -> false

  eqList : {{_ : Eq A}} -> Eq (List A)
  eqList ._==_ = λ where
    [] [] -> true
    (a :: as) (a' :: as') -> a == a' && as == as'
    _ _ -> false

  eqIdentity : {{_ : Eq A}} -> Eq (Identity A)
  eqIdentity ._==_ (anIdentity a) (anIdentity a') = a == a'

  eqConst : {{_ : Eq A}} -> Eq (Const A B)
  eqConst ._==_ (aConst a) (aConst a') = a == a'

--------------------------------------------------------------------------------
-- Ord
--------------------------------------------------------------------------------

data Ordering : Set where
  LT EQ GT : Ordering

record Ord (A : Set) : Set where
  infixl 4 _<_
  field
    overlap {{super}} : Eq A
    _<_ : A -> A -> Bool

  compare : A -> A -> Ordering
  compare a a' = if a < a' then LT else if a == a' then EQ else GT

  infixl 4 _≤_
  _≤_ : A -> A -> Bool
  a ≤ a' = if a < a' then true else if a == a' then true else false

  infixl 4 _>_
  _>_ : A -> A -> Bool
  _>_ = flip _<_

  infixl 4 _≥_
  _≥_ : A -> A -> Bool
  _≥_ = flip _≤_

  min : A -> A -> A
  min x y = if x < y then x else y

  max : A -> A -> A
  max x y = if x < y then y else x

  comparing : (B -> A) -> B -> B -> Ordering
  comparing p b b' = compare (p b) (p b')

open Ord {{...}} public

instance
  ordVoid : Ord Void
  ordVoid ._<_ = λ ()

  ordUnit : Ord Unit
  ordUnit ._<_ unit unit = false

  ordBool : Ord Bool
  ordBool ._<_ = λ where
    false true -> true
    _ _ -> false

  ordNat : Ord Nat
  ordNat ._<_ = Agda.Builtin.Nat._<_

  ordInt : Ord Int
  ordInt ._<_ = λ where
    (pos m) (pos n) -> m < n
    (negsuc m) (negsuc n) -> m > n
    (negsuc _) (pos _) -> true
    (pos _) (negsuc _) -> false

  ordFloat : Ord Float
  ordFloat ._<_ = Agda.Builtin.Float.primFloatNumericalLess

  ordChar : Ord Char
  ordChar ._<_ c c' = ord c < ord c'

  ordList : {{_ : Ord A}} -> Ord (List A)
  ordList ._<_ = λ where
    (a :: as) (a' :: as') -> a < a' || (a == a' && as < as')
    [] [] -> true
    _ _ -> false

  ordString : Ord String
  ordString ._<_ s s' with unpack s | unpack s'
  ... | (c :: cs) | (c' :: cs') = c < c' || (c == c' && cs < cs')
  ... | _ | _ = false

  ordPair : {{_ : Ord A}} {{_ : Ord B}} -> Ord (Pair A B)
  ordPair ._<_ (a , b) (a' , b') = a < a' || (a == a' && b < b')

  ordMaybe : {{_ : Ord A}} -> Ord (Maybe A)
  ordMaybe ._<_ = λ where
    _ nothing -> false
    nothing _ -> true
    (just a) (just a') -> a < a'

  ordIdentity : {{_ : Ord A}} -> Ord (Identity A)
  ordIdentity ._<_ (anIdentity a) (anIdentity a') = a < a'

  ordConst : {{_ : Ord A}} -> Ord (Const A B)
  ordConst ._<_ (aConst a) (aConst a') = a < a'

--------------------------------------------------------------------------------
-- Semigroup
--------------------------------------------------------------------------------

record Semigroup (A : Set) : Set where
  infixr 5 _<>_
  field _<>_ : A -> A -> A

open Semigroup {{...}} public

infixr 6 _+_
_+_ : {{_ : Semigroup (Sum A)}} -> A -> A -> A
a + a' = getSum (aSum a <> aSum a')

infixr 7 _*_
_*_ : {{_ : Semigroup (Product A)}} -> A -> A -> A
a * a' = getProduct (aProduct a <> aProduct a')

instance
  semigroupDual : {{_ : Semigroup A}} -> Semigroup (Dual A)
  semigroupDual ._<>_ (aDual a) (aDual a') = aDual (a' <> a)

  semigroupFirst : Semigroup (First A)
  semigroupFirst ._<>_ a _ = a

  semigroupLast : Semigroup (Last A)
  semigroupLast ._<>_ _ a = a

  semigroupVoid : Semigroup Void
  semigroupVoid ._<>_ = λ ()

  semigroupSumSet : Semigroup (Sum Set)
  semigroupSumSet ._<>_ (aSum A) (aSum B) = aSum (Either A B)

  semigroupProductSet : Semigroup (Product Set)
  semigroupProductSet ._<>_ (aProduct A) (aProduct B) = aProduct (Pair A B)

  semigroupUnit : Semigroup Unit
  semigroupUnit ._<>_ unit unit = unit

  semigroupAny : Semigroup Any
  semigroupAny ._<>_ (anAny b) (anAny b') = anAny (b || b')

  semigroupAll : Semigroup All
  semigroupAll ._<>_ (anAll b) (anAll b') = anAll (b && b')

  semigroupSumNat : Semigroup (Sum Nat)
  semigroupSumNat ._<>_ (aSum m) (aSum n) = aSum (Agda.Builtin.Nat._+_ m n)

  semigroupProductNat : Semigroup (Product Nat)
  semigroupProductNat ._<>_ (aProduct m) (aProduct n) =
    aProduct (Agda.Builtin.Nat._*_ m n)

  semigroupSumInt : Semigroup (Sum Int)
  semigroupSumInt ._<>_ (aSum m') (aSum n') =
    aSum $ case (m' , n') of λ where
      (negsuc m , negsuc n) -> negsuc (suc (m + n))
      (negsuc m , pos n) -> sub n (suc m)
      (pos m , negsuc n) -> sub m (suc n)
      (pos m , pos n) -> pos (m + n)

  semigroupProductInt : Semigroup (Product Int)
  semigroupProductInt ._<>_ (aProduct n') (aProduct m') =
    aProduct $ case (n' , m') of λ where
      (pos n , pos m) -> pos (n * m)
      (negsuc n , negsuc m) -> pos (suc n * suc m)
      (pos n , negsuc m) -> neg (n * suc m)
      (negsuc n , pos m) -> neg (suc n * m)

  semigroupSumFloat : Semigroup (Sum Float)
  semigroupSumFloat ._<>_ (aSum x) (aSum y) =
    aSum (Agda.Builtin.Float.primFloatPlus x y)

  semigroupProductFloat : Semigroup (Product Float)
  semigroupProductFloat ._<>_ (aProduct x) (aProduct y) =
    aProduct (Agda.Builtin.Float.primFloatTimes x y)

  semigroupString : Semigroup String
  semigroupString ._<>_ = Agda.Builtin.String.primStringAppend

  semigroupFunction : {{_ : Semigroup B}} -> Semigroup (A -> B)
  semigroupFunction ._<>_ f g = λ a -> f a <> g a

  semigroupFunctionSum : {{_ : Semigroup (Sum B)}} -> Semigroup (Sum (A -> B))
  semigroupFunctionSum ._<>_ (aSum f) (aSum g) = aSum (λ a -> f a + g a)

  semigroupFunctionProduct : {{_ : Semigroup (Product B)}}
    -> Semigroup (Product (A -> B))
  semigroupFunctionProduct ._<>_ (aProduct f) (aProduct g) =
    aProduct (λ a -> f a * g a)

  semigroupEndo : Semigroup (Endo A)
  semigroupEndo ._<>_ g f = anEndo (appEndo g ∘ appEndo f)

  semigroupEither : {{_ : Semigroup A}} {{_ : Semigroup B}}
    -> Semigroup (Either A B)
  semigroupEither ._<>_ (left _) b = b
  semigroupEither ._<>_ a _ = a

  semigroupPair : {{_ : Semigroup A}} {{_ : Semigroup B}}
    -> Semigroup (Pair A B)
  semigroupPair ._<>_ (a , b) (a' , b') = (a <> a' , b <> b')

  semigroupMaybe : {{_ : Semigroup A}} -> Semigroup (Maybe A)
  semigroupMaybe ._<>_ = λ where
    nothing m -> m
    m nothing -> m
    (just a) (just a') -> just (a <> a')

  semigroupList : Semigroup (List A)
  semigroupList ._<>_ as as' = listrec as' (λ x _ xs -> x :: xs) as

  semigroupIO : {{_ : Semigroup A}} -> Semigroup (IO A)
  semigroupIO ._<>_ x y = let _<*>_ = apIO; pure = pureIO in
    (| _<>_ x y |)

  semigroupIdentity : {{_ : Semigroup A}} -> Semigroup (Identity A)
  semigroupIdentity ._<>_ (anIdentity a) (anIdentity a') =
    anIdentity (a <> a')

  semigroupConst : {{_ : Semigroup A}} -> Semigroup (Const A B)
  semigroupConst ._<>_ (aConst a) (aConst a') = aConst (a <> a')

--------------------------------------------------------------------------------
-- Monoid
--------------------------------------------------------------------------------

record Monoid (A : Set) : Set where
  field
    overlap {{super}} : Semigroup A
    neutral : A

  when : Bool -> A -> A
  when true a = a
  when false _ = neutral

  unless : Bool -> A -> A
  unless true _ = neutral
  unless false a = a

open Monoid {{...}} public

-- For additive monoids
zero : {{_ : Monoid (Sum A)}} -> A
zero = getSum neutral

-- For multiplicative monoids
one : {{_ : Monoid (Product A)}} -> A
one = getProduct neutral

infixr 8 _^_
_^_ : {{_ : Monoid (Product A)}} -> A -> Nat -> A
a ^ 0 = one
a ^ (suc n) = a * a ^ n

instance
  monoidDual : {{_ : Monoid A}} -> Monoid (Dual A)
  monoidDual .neutral = aDual neutral

  monoidFirst : {{_ : Monoid A}} -> Monoid (First A)
  monoidFirst .neutral = aFirst neutral

  monoidLast : {{_ : Monoid A}} -> Monoid (Last A)
  monoidLast .neutral = aLast neutral

  monoidSumSet : Monoid (Sum Set)
  monoidSumSet .neutral = aSum Void

  monoidProductSet : Monoid (Product Set)
  monoidProductSet .neutral = aProduct Unit

  monoidUnit : Monoid Unit
  monoidUnit .neutral = unit

  monoidAll : Monoid All
  monoidAll .neutral = anAll true

  monoidAny : Monoid Any
  monoidAny .neutral = anAny false

  monoidSumNat : Monoid (Sum Nat)
  monoidSumNat .neutral = aSum 0

  monoidProductNat : Monoid (Product Nat)
  monoidProductNat .neutral = aProduct 1

  monoidSumInt : Monoid (Sum Int)
  monoidSumInt .neutral = aSum (pos 0)

  monoidProductInt : Monoid (Product Int)
  monoidProductInt .neutral = aProduct (pos 1)

  monoidSumFloat : Monoid (Sum Float)
  monoidSumFloat .neutral = aSum 0.0

  monoidProductFloat : Monoid (Product Float)
  monoidProductFloat .neutral = aProduct 1.0

  monoidString : Monoid String
  monoidString .neutral = ""

  monoidFunction : {{_ : Monoid B}} -> Monoid (A -> B)
  monoidFunction .neutral = const neutral

  monoidFunctionSum : {{_ : Monoid (Sum B)}} -> Monoid $ Sum (A -> B)
  monoidFunctionSum .neutral = aSum (const zero)

  monoidFunctionProduct : {{_ : Monoid (Product B)}}
    -> Monoid $ Product (A -> B)
  monoidFunctionProduct .neutral = aProduct (const one)

  monoidEndo : Monoid (Endo A)
  monoidEndo .neutral = anEndo id

  monoidMaybe : {{_ : Semigroup A}} -> Monoid (Maybe A)
  monoidMaybe .neutral = nothing

  monoidList : Monoid (List A)
  monoidList .neutral = []

  monoidIO : {{_ : Monoid A}} -> Monoid (IO A)
  monoidIO .neutral = pureIO neutral

  monoidIdentity : {{_ : Monoid A}} -> Monoid (Identity A)
  monoidIdentity .neutral = anIdentity neutral

  monoidConst : {{_ : Monoid A}} -> Monoid (Const A B)
  monoidConst .neutral = aConst neutral

--------------------------------------------------------------------------------
-- Semiring
--------------------------------------------------------------------------------

record Semiring (A : Set) : Set where
  field
    {{monoidSum}} : Monoid (Sum A)
    {{monoidProduct}} : Monoid (Product A)
    Nonzero : A -> Set

open Semiring {{...}} public

instance
  semiringNat : Semiring Nat
  semiringNat .Nonzero 0 = Void
  semiringNat .Nonzero (suc _) = Unit

  semiringInt : Semiring Int
  semiringInt .Nonzero (pos 0) = Void
  semiringInt .Nonzero _ = Unit

  semiringFloat : Semiring Float
  semiringFloat .Nonzero x = if x == 0.0 then Void else Unit

--------------------------------------------------------------------------------
-- EuclideanSemiring
--------------------------------------------------------------------------------

record EuclideanSemiring (A : Set) : Set where
  field
    {{super}} : Semiring A
    degree : A -> Nat
    quot : (a a' : A) {_ : Nonzero a'} -> A
    mod : (a a' : A) {_ : Nonzero a'} -> A

open EuclideanSemiring {{...}} public

instance
  euclideanSemiringNat : EuclideanSemiring Nat
  euclideanSemiringNat .degree n = n
  euclideanSemiringNat .quot m 0 = 0 -- unreachable
  euclideanSemiringNat .quot m (suc n) = Agda.Builtin.Nat.div-helper 0 n m n
  euclideanSemiringNat .mod m 0 = 0 -- unreachable
  euclideanSemiringNat .mod m (suc n) = Agda.Builtin.Nat.mod-helper 0 n m n

--------------------------------------------------------------------------------
-- Ring
--------------------------------------------------------------------------------

record Ring (A : Set) : Set where
  infixr 6 _-_
  field
    overlap {{super}} : Semiring A
    -_ : A -> A
    _-_ : A -> A -> A

  abs : {{_ : Ord A}} -> A -> A
  abs a = if a < zero then - a else a

open Ring {{...}} public

instance
  ringInt : Ring Int
  ringInt .-_ = λ where
    (pos 0) -> pos 0
    (pos (suc n)) -> negsuc n
    (negsuc n) -> pos (suc n)
  ringInt ._-_ n m = n + (- m)

  ringFloat : Ring Float
  ringFloat .-_ = Agda.Builtin.Float.primFloatNegate
  ringFloat ._-_ = Agda.Builtin.Float.primFloatMinus

--------------------------------------------------------------------------------
-- Field
--------------------------------------------------------------------------------

record Field (A : Set) : Set where
  infixr 7 _/_
  field
    overlap {{super}} : Ring A
    _/_ : (a a' : A) -> {_ : Nonzero a'} -> A

open Field {{...}} public

instance
  fieldFloat : Field Float
  fieldFloat ._/_ x y = Agda.Builtin.Float.primFloatDiv x y

--------------------------------------------------------------------------------
-- IsBuildable, Buildable
--------------------------------------------------------------------------------

record IsBuildable (S A : Set) : Set where
  field
    {{monoid}} : Monoid S
    singleton : A -> S

  infixr 5 _++_
  _++_ : S -> S -> S
  _++_ = _<>_

  nil : S
  nil = neutral

  cons : A -> S -> S
  cons a s = singleton a ++ s

  snoc : S -> A -> S
  snoc s a = s ++ singleton a

open IsBuildable {{...}} public

Buildable : (Set -> Set) -> Set
Buildable F = ∀ {A} -> IsBuildable (F A) A

instance
  buildableList : Buildable List
  buildableList .singleton = _:: []

  isBuildableStringChar : IsBuildable String Char
  isBuildableStringChar .singleton = pack ∘ singleton

--------------------------------------------------------------------------------
-- Functor, Contravariant, Bifunctor, Profunctor
--------------------------------------------------------------------------------

infixr 0 _~>_
_~>_ : (F G : Set -> Set) -> Set
F ~> G  = ∀ {A} -> F A -> G A

record Functor (F : Set -> Set) : Set where
  field map : (A -> B) -> F A -> F B

  infixl 4 _<$>_
  _<$>_ : (A -> B) -> F A -> F B
  _<$>_ = map

  infixl 4 _<$_
  _<$_ : B -> F A -> F B
  _<$_ = map ∘ const

  infixl 4 _$>_
  _$>_ : F A -> B -> F B
  _$>_ = flip _<$_

  void : F A -> F Unit
  void = unit <$_

open Functor {{...}} public

record Contravariant (F : Set -> Set) : Set where
  field contramap : (A -> B) -> F B -> F A

  phantom : {{_ : Functor F}} -> F A -> F B
  phantom x = contramap (const unit) $ map (const unit) x

open Contravariant {{...}} public

record Bifunctor (P : Set -> Set -> Set) : Set where
  field bimap : (A -> B) -> (C -> D) -> P A C -> P B D

  first : (A -> B) -> P A C -> P B C
  first f = bimap f id

  second : (B -> C) -> P A B -> P A C
  second g = bimap id g

open Bifunctor {{...}} public

record Profunctor (P : Set -> Set -> Set) : Set where
  field dimap : (A -> B) -> (C -> D) -> P B C -> P A D

  lmap : (A -> B) -> P B C -> P A C
  lmap f = dimap f id

  rmap : (B -> C) -> P A B -> P A C
  rmap f = dimap id f

open Profunctor {{...}} public

instance
  bifunctorEither : Bifunctor Either
  bifunctorEither .bimap f g = either (left ∘ f) (right ∘ g)

  functorEither : Functor (Either A)
  functorEither .map = second

  bifunctorPair : Bifunctor Pair
  bifunctorPair .bimap f g = split (f ∘ fst) (g ∘ snd)

  functorPair : Functor (Pair A)
  functorPair .map = second

  functorMaybe : Functor Maybe
  functorMaybe .map f = λ where
    nothing -> nothing
    (just a) -> just (f a)

  functorList : Functor List
  functorList .map f = listrec [] λ a _ bs -> f a :: bs

  functorIO : Functor IO
  functorIO .map = mapIO

  functorIdentity : Functor Identity
  functorIdentity .map f = anIdentity ∘ f ∘ runIdentity

  bifunctorConst : Bifunctor Const
  bifunctorConst .bimap f g = aConst ∘ f ∘ getConst

  functorConst : Functor (Const A)
  functorConst .map = second

  contravariantConst : Contravariant (Const A)
  contravariantConst .contramap f = aConst ∘ getConst

  functorSum : Functor Sum
  functorSum .map f = aSum ∘ f ∘ getSum

  functorProduct : Functor Product
  functorProduct .map f = aProduct ∘ f ∘ getProduct

  functorDual : Functor Dual
  functorDual .map f = aDual ∘ f ∘ getDual

  functorFirst : Functor First
  functorFirst .map f = aFirst ∘ f ∘ getFirst

  functorLast : Functor Last
  functorLast .map f = aLast ∘ f ∘ getLast

  functorMin : Functor Min
  functorMin .map f = aMin ∘ f ∘ getMin

  functorMax : Functor Max
  functorMax .map f = aMax ∘ f ∘ getMax

  profunctorFunction : Profunctor Function
  profunctorFunction .dimap f g h = g ∘ h ∘ f

--------------------------------------------------------------------------------
-- Applicative
--------------------------------------------------------------------------------

record Applicative (F : Set -> Set) : Set where
  infixl 4 _<*>_
  field
    overlap {{super}} : Functor F
    _<*>_ : F (A -> B) -> F A -> F B
    pure : A -> F A

  infixl 4 _*>_
  _*>_ : F A -> F B -> F B
  a *> b = (| (flip const) a b |)

  infixl 4 _<*_
  _<*_ : F A -> F B -> F A
  a <* b = (| const a b |)

  map2 : (A -> B -> C) -> F A -> F B -> F C
  map2 f a b = (| f a b |)

open Applicative {{...}} public

instance
  applicativeEither : Applicative (Either A)
  applicativeEither .pure = right
  applicativeEither ._<*>_ = λ where
    (left a) _ -> left a
    (right f) -> map f

  applicativeMaybe : Applicative Maybe
  applicativeMaybe .pure = just
  applicativeMaybe ._<*>_ = λ where
    (just f) -> map f
    nothing _ -> nothing

  applicativeList : Applicative List
  applicativeList .pure = singleton
  applicativeList ._<*>_ = λ where
    [] _ -> []
    _ [] -> []
    (f :: fs) (x :: xs) -> f x :: (fs <*> xs)

  applicativeIO : Applicative IO
  applicativeIO .pure = pureIO
  applicativeIO ._<*>_ = apIO

  applicativeIdentity : Applicative Identity
  applicativeIdentity .pure = anIdentity
  applicativeIdentity ._<*>_ = map ∘ runIdentity

  applicativeConst : {{_ : Monoid A}} -> Applicative (Const A)
  applicativeConst .pure _ = aConst neutral
  applicativeConst ._<*>_ (aConst f) (aConst a) = aConst (f <> a)

  applicativeSum : Applicative Sum
  applicativeSum .pure = aSum
  applicativeSum ._<*>_ (aSum f) (aSum x) = aSum (f x)

  applicativeProduct : Applicative Product
  applicativeProduct .pure = aProduct
  applicativeProduct ._<*>_ (aProduct f) (aProduct x) = aProduct (f x)

  applicativeDual : Applicative Dual
  applicativeDual .pure = aDual
  applicativeDual ._<*>_ (aDual f) (aDual x) = aDual (f x)

  applicativeFirst : Applicative First
  applicativeFirst .pure = aFirst
  applicativeFirst ._<*>_ (aFirst f) (aFirst x) = aFirst (f x)

  applicativeLast : Applicative Last
  applicativeLast .pure = aLast
  applicativeLast ._<*>_ (aLast f) (aLast x) = aLast (f x)

  applicativeMin : Applicative Min
  applicativeMin .pure = aMin
  applicativeMin ._<*>_ (aMin f) (aMin x) = aMin (f x)

  applicativeMax : Applicative Max
  applicativeMax .pure = aMax
  applicativeMax ._<*>_ (aMax f) (aMax x) = aMax (f x)

--------------------------------------------------------------------------------
-- Alternative
--------------------------------------------------------------------------------

record Alternative (F : Set -> Set) : Set where
  infixl 3 _<|>_
  field
    overlap {{super}} : Applicative F
    _<|>_ : F A -> F A -> F A
    empty : F A

open Alternative {{...}} public

module _ {{_ : Alternative F}} where

  {-# NON_TERMINATING #-}
  many1 many : F A -> F (List A)
  many1 a = (| _::_ a (many a) |)
  many a = many1 a <|> pure []

  optional : F A -> F (Maybe A)
  optional a = just <$> a <|> pure nothing

  eitherA : F A -> F B -> F (Either A B)
  eitherA a b = (map left a) <|> (map right b)

instance
  alternativeMaybe : Alternative Maybe
  alternativeMaybe .empty = nothing
  alternativeMaybe ._<|>_ = λ where
    nothing r -> r
    l _ -> l

  alternativeList : Alternative List
  alternativeList .empty = neutral
  alternativeList ._<|>_ = _<>_

--------------------------------------------------------------------------------
-- Monad
--------------------------------------------------------------------------------

record Monad (M : Set -> Set) : Set where
  infixl 1 _>>=_
  field
    overlap {{super}} : Applicative M
    _>>=_ : M A -> (A -> M B) -> M B

  return : A -> M A
  return = pure

  join : M (M A) -> M A
  join = _>>= id

  infixl 1 _>>_
  _>>_ : M A -> M B -> M B
  _>>_ = _*>_

open Monad {{...}} public

instance
  monadEither : Monad (Either A)
  monadEither ._>>=_ = λ where
    (left a) k -> left a
    (right x) k -> k x

  monadMaybe : Monad Maybe
  monadMaybe ._>>=_ = λ where
    nothing k -> nothing
    (just x) k -> k x

  monadList : Monad List
  monadList ._>>=_ = λ where
    [] k -> []
    (x :: xs) k -> k x ++ (xs >>= k)

  monadIO : Monad IO
  monadIO ._>>=_ = bindIO

  monadIdentity : Monad Identity
  monadIdentity ._>>=_ (anIdentity x) k = k x

  monadSum : Monad Sum
  monadSum ._>>=_ (aSum x) k = k x

  monadProduct : Monad Product
  monadProduct ._>>=_ (aProduct x) k = k x

  monadDual : Monad Dual
  monadDual ._>>=_ (aDual x) k = k x

  monadFirst : Monad First
  monadFirst ._>>=_ (aFirst x) k = k x

  monadLast : Monad Last
  monadLast ._>>=_ (aLast x) k = k x

  monadMin : Monad Min
  monadMin ._>>=_ (aMin x) k = k x

  monadMax : Monad Max
  monadMax ._>>=_ (aMax x) k = k x

--------------------------------------------------------------------------------
-- IsFoldable, Foldable
--------------------------------------------------------------------------------

record IsFoldable (S A : Set) : Set where
  field foldMap : {{_ : Monoid B}} -> (A -> B) -> S -> B

  fold : {{_ : Monoid A}} -> S -> A
  fold = foldMap id

  foldr : (A -> B -> B) -> B -> S -> B
  foldr f b as = appEndo (foldMap (anEndo ∘ f) as) b

  foldl : (B -> A -> B) -> B -> S -> B
  foldl f b as =
    (appEndo ∘ getDual) (foldMap (aDual ∘ anEndo ∘ flip f) as) b

  foldrM : {{_ : Monad M}} -> (A -> B -> M B) -> B -> S -> M B
  foldrM f b as = let g k a b' = f a b' >>= k in
    foldl g return as b

  foldlM : {{_ : Monad M}} -> (B -> A -> M B) -> B -> S -> M B
  foldlM f b as = let g a k b' = f b' a >>= k in
    foldr g return as b

  count : S -> Nat
  count = getSum ∘ foldMap (const $ aSum 1)

  all : (A -> Bool) -> S -> Bool
  all p = getAll ∘ foldMap (anAll ∘ p)

  any : (A -> Bool) -> S -> Bool
  any p = getAny ∘ foldMap (anAny ∘ p)

  null : S -> Bool
  null = not ∘ any (const true)

  sum : {{ _ : Monoid (Sum A)}} -> S -> A
  sum = getSum ∘ foldMap aSum

  product : {{ _ : Monoid (Product A)}} -> S -> A
  product = getProduct ∘ foldMap aProduct

  module _ {{_ : Eq A}} where

    elem : A -> S -> Bool
    elem = any ∘ _==_

    notElem : A -> S -> Bool
    notElem a s = not (elem a s)

  module _ {{_ : Applicative F}} where

    traverse! : (A -> F B) -> S -> F Unit
    traverse! f = foldr (_*>_ ∘ f) (pure unit)

    for! : S -> (A -> F B) -> F Unit
    for! = flip traverse!

  module _ {{_ : BooleanAlgebra A}} where

    or : S -> A
    or = foldr _||_ ff

    and : S -> A
    and = foldr _&&_ tt

open IsFoldable {{...}} public

sequence! : {{_ : Applicative F}} {{_ : IsFoldable S (F A)}} -> S -> F Unit
sequence! = traverse! id

Foldable : (Set -> Set) -> Set
Foldable F = ∀ {A} -> IsFoldable (F A) A

instance
  foldableEither : Foldable (Either A)
  foldableEither .foldMap _ (left _) = neutral
  foldableEither .foldMap f (right x) = f x

  foldablePair : Foldable (Pair A)
  foldablePair .foldMap f (_ , x) = f x

  foldableMaybe : Foldable Maybe
  foldableMaybe .foldMap = maybe neutral

  foldableList : Foldable List
  foldableList .foldMap f = listrec neutral λ x _ y -> f x <> y

  isFoldableStringChar : IsFoldable String Char
  isFoldableStringChar .foldMap f = foldMap f ∘ unpack

--------------------------------------------------------------------------------
-- Traversable
--------------------------------------------------------------------------------

private
  record StateL (S A : Set) : Set where
    constructor aStateL
    field runStateL : S -> Pair S A

  open StateL

  record StateR (S A : Set) : Set where
    constructor aStateR
    field runStateR : S -> Pair S A

  open StateR

  instance
    functorStateL : Functor (StateL S)
    functorStateL .map f (aStateL t) = aStateL λ s₀ ->
      let (s₁ , x) = t s₀ in (s₁ , f x)

    functorStateR : Functor (StateR S)
    functorStateR .map f (aStateR t) = aStateR λ s₀ ->
      let (s₁ , x) = t s₀ in (s₁ , f x)

    applicativeStateL : Applicative (StateL S)
    applicativeStateL .pure x = aStateL λ s -> (s , x)
    applicativeStateL ._<*>_ (aStateL f) (aStateL t) = aStateL λ s₀ ->
      let (s₁ , f') = f s₀; (s₂ , x) = t s₁ in (s₂ , f' x)

    applicativeStateR : Applicative (StateR S)
    applicativeStateR .pure x = aStateR λ s -> (s , x)
    applicativeStateR ._<*>_ (aStateR f) (aStateR t) = aStateR λ s₀ ->
      let (s₁ , x) = t s₀; (s₂ , f') = f s₁ in (s₂ , f' x)

record Traversable (T : Set -> Set) : Set where
  field
    {{superFunctor}} : Functor T
    {{superFoldable}} : Foldable T
    traverse : {{_ : Applicative F}} -> (A -> F B) -> T A -> F (T B)

  sequence : {{_ : Applicative F}} -> T (F A) -> F (T A)
  sequence = traverse id

  for : {{_ : Applicative F}} -> T A -> (A -> F B) -> F (T B)
  for = flip traverse

  mapAccumL : (A -> B -> Pair A C) -> A -> T B -> Pair A (T C)
  mapAccumL f a xs = runStateL (traverse (aStateL ∘ flip f) xs) a

  mapAccumR : (A -> B -> Pair A C) -> A -> T B -> Pair A (T C)
  mapAccumR f a xs = runStateR (traverse (aStateR ∘ flip f) xs) a

  scanl : (B -> A -> B) -> B -> T A -> T B
  scanl f b₀ xs = snd (mapAccumL (λ b a -> dupe (f b a)) b₀ xs)

  scanr : (A -> B -> B) -> B -> T A -> T B
  scanr f b₀ xs = snd (mapAccumR (λ b a -> dupe (f a b)) b₀ xs)

open Traversable {{...}} public

instance
  traversableEither : Traversable (Either A)
  traversableEither .traverse f = λ where
    (left a) -> pure (left a)
    (right x) -> map right (f x)

  traversablePair : Traversable (Pair A)
  traversablePair .traverse f (x , y) = _,_ x <$> f y

  traversableMaybe : Traversable Maybe
  traversableMaybe .traverse f = λ where
    nothing -> pure nothing
    (just x) -> just <$> f x

  traversableList : Traversable List
  traversableList .traverse f = listrec (pure []) λ where
    x _ ys -> (| _::_ (f x) ys |)

--------------------------------------------------------------------------------
-- Show
--------------------------------------------------------------------------------

record Show (A : Set) : Set where
  field show : A -> String

  print : A -> IO Unit
  print x = putStrLn (show x)

open Show {{...}} public

instance
  showVoid : Show Void
  showVoid .show ()

  showUnit : Show Unit
  showUnit .show unit = "unit"

  showBool : Show Bool
  showBool .show true = "true"
  showBool .show false = "false"

  showNat : Show Nat
  showNat .show = Agda.Builtin.String.primShowNat

  showInt : Show Int
  showInt .show = Agda.Builtin.Int.primShowInteger

  showFloat : Show Float
  showFloat .show = Agda.Builtin.Float.primShowFloat

  showPair : {{_ : Show A}} {{_ : Show B}} -> Show (Pair A B)
  showPair .show (x , y) = "(" ++ show x ++ " , " ++ show y ++ ")"

  showEither : {{_ : Show A}} {{_ : Show B}} -> Show (Either A B)
  showEither .show = λ where
    (left x) -> "left " ++ show x
    (right y) -> "right " ++ show y

  showMaybe : {{_ : Show A}} -> Show (Maybe A)
  showMaybe .show = λ where
    (just x) -> "just " ++ show x
    nothing -> "nothing"

  showList : {{_ : Show A}} -> Show (List A)
  showList .show [] = "[]"
  showList .show as = "(" ++ show' as ++ ")"
    where
      show' : {{_ : Show A}} -> List A -> String
      show' [] = "[]"
      show' (x :: xs) = show x ++ " :: " ++ show' xs

  showChar : Show Char
  showChar .show = Agda.Builtin.String.primShowChar

  showString : Show String
  showString .show = Agda.Builtin.String.primShowString
