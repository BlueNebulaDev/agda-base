{-# OPTIONS --type-in-type #-}

module Prelude where

private
  variable
    A B C D R S : Set
    F M : Set -> Set

--------------------------------------------------------------------------------
-- Primitive types and type constructors
--------------------------------------------------------------------------------

data Void : Set where

open import Agda.Builtin.Unit public
  renaming (⊤ to Unit; tt to unit)

open import Agda.Builtin.Bool public
  using (Bool)
  renaming (true to True; false to False)

open import Agda.Builtin.Nat public
  using (Nat)
  renaming (suc to Suc; zero to Zero)

open import Agda.Builtin.Int public
  using (Int)
  renaming (pos to Pos; negsuc to NegSuc)

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
  Left : A -> Either A B
  Right : B -> Either A B

{-# COMPILE GHC Either = data Either (Left | Right) #-}

infixl 1 _,_
record Tuple (A B : Set) : Set where
  constructor _,_
  field
    fst : A
    snd : B

open Tuple public

{-# COMPILE GHC Tuple = data (,) ((,)) #-}

data Maybe (A : Set) : Set where
  Nothing : Maybe A
  Just : A -> Maybe A

{-# COMPILE GHC Maybe = data Maybe (Nothing | Just) #-}

open import Agda.Builtin.List public
  using (List; [])
  renaming (_∷_ to _::_)

open import Agda.Builtin.IO public
  using (IO)

--------------------------------------------------------------------------------
-- Wrappers
--------------------------------------------------------------------------------

record Identity (A : Set) : Set where
  constructor Identity:
  field runIdentity : A

open Identity public

record Const (A B : Set) : Set where
  constructor Const:
  field getConst : A

open Const public

-- Endofunctions
record Endo A : Set where
  constructor Endo:
  field appEndo : A -> A

open Endo public

--------------------------------------------------------------------------------
-- Primitive functions and operations
--------------------------------------------------------------------------------

open import Agda.Builtin.TrustMe public
  renaming (primTrustMe to trustMe)

postulate
  believeMe : A
  error : String -> A

{-# FOREIGN GHC import qualified Data.Text #-}
{-# COMPILE GHC error = \ _ s -> error (Data.Text.unpack s) #-}

undefined : A
undefined = error "Prelude.undefined"

id : A -> A
id a = a

const : A -> B -> A
const a _ = a

flip : (A -> B -> C) -> B -> A -> C
flip f b a = f a b

infixr 0 _$_
_$_ : (A -> B) -> A -> B
_$_ = id

infixl 1 _#_
_#_ : A -> (A -> B) -> B
_#_ = flip _$_

case_of_ : A -> (A -> B) -> B
case_of_ = _#_

infixr 9 _∘_
_∘_ : (B -> C) -> (A -> B) -> A -> C
g ∘ f = λ a -> g (f a)

So : Bool -> Set
So False = Void
So True = Unit

infixr 10 if_then_else_
if_then_else_ : Bool -> A -> A -> A
if True then a else _ = a
if False then _ else a = a

natrec : A -> (Nat -> A -> A) -> Nat -> A
natrec a _ 0 = a
natrec a h n@(Suc n-1) = h n-1 (natrec a h n-1)

applyN : (A -> A) -> Nat -> A -> A
applyN f n a = natrec a (const f) n

pred : Nat -> Nat
pred 0 = 0
pred (Suc n) = n

neg : Nat -> Int
neg 0 = Pos 0
neg (Suc n) = NegSuc n

foldZ : (Nat -> A) -> (Nat -> A) -> Int -> A
foldZ f g (Pos n) = f n
foldZ f g (NegSuc n) = g n

isPos : Int -> Bool
isPos (Pos _) = True
isPos _ = False

IsPos : Int -> Set
IsPos (Pos _) = Unit
IsPos _ = Void

fromPos : (i : Int) {_ : IsPos i} -> Nat
fromPos (Pos n) = n

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

intToFloat : Int -> Float
intToFloat (Pos n) = natToFloat n
intToFloat (NegSuc n) = Agda.Builtin.Float.primFloatMinus -1.0 (natToFloat n)

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
either f g (Left a) = f a
either f g (Right b) = g b

mirror : Either A B -> Either B A
mirror = either Right Left

untag : Either A A -> A
untag (Left a) = a
untag (Right a) = a

isLeft : Either A B -> Bool
isLeft (Left _) = True
isLeft _ = False

isRight : Either A B -> Bool
isRight (Left _) = False
isRight _ = True

fromLeft : A -> Either A B -> A
fromLeft _ (Left a) = a
fromLeft a (Right _) = a

fromRight : B -> Either A B -> B
fromRight b (Left _) = b
fromRight _ (Right b) = b

fromEither : (A -> B) -> Either A B -> B
fromEither f (Left a) = f a
fromEither _ (Right b) = b

tuple : (A -> B) -> (A -> C) -> A -> Tuple B C
tuple f g a = (f a , g a)

swap : Tuple A B -> Tuple B A
swap = tuple snd fst

dupe : A -> Tuple A A
dupe a = (a , a)

uncurry : (A -> B -> C) -> Tuple A B -> C
uncurry f (a , b) = f a b

curry : (Tuple A B -> C) -> A -> B -> C
curry f a b = f (a , b)

apply : Tuple (A -> B) A -> B
apply = uncurry _$_

isJust : Maybe A -> Bool
isJust (Just _) = True
isJust _ = False

isNothing : Maybe A -> Bool
isNothing (Just _) = False
isNothing _ = True

fromJust : (x : Maybe A) {{_ : So $ isJust x}} -> A
fromJust (Just a) = a

maybe : B -> (A -> B) -> Maybe A -> B
maybe b f Nothing = b
maybe b f (Just a) = f a

maybeToLeft : B -> Maybe A -> Either A B
maybeToLeft b = maybe (Right b) Left

maybeToRight : B -> Maybe A -> Either B A
maybeToRight b = mirror ∘ maybeToLeft b

leftToMaybe : Either A B -> Maybe A
leftToMaybe = either Just (const Nothing)

RightToMaybe : Either A B -> Maybe B
RightToMaybe = leftToMaybe ∘ mirror

pattern [_] x = x :: []

listrec : B -> (A -> List A -> B -> B) -> List A -> B
listrec b f [] = b
listrec b f (a :: as) = f a as (listrec b f as)

maybeToList : Maybe A -> List A
maybeToList Nothing = []
maybeToList (Just a) = a :: []

listToMaybe : List A -> Maybe A
listToMaybe [] = Nothing
listToMaybe (a :: _) = Just a

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
{-# COMPILE GHC mapIO = \ _ _ -> fmap #-}
{-# COMPILE GHC pureIO = \ _ -> pure #-}
{-# COMPILE GHC apIO = \ _ _ -> (<*>) #-}
{-# COMPILE GHC bindIO = \ _ _ -> (>>=) #-}
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
  booleanAlgebraBool .ff = False
  booleanAlgebraBool .tt = True
  booleanAlgebraBool .not = λ where
    False -> True
    True -> False
  booleanAlgebraBool ._||_ = λ where
    False b -> b
    True _ -> True
  booleanAlgebraBool ._&&_ = λ where
    False _ -> False
    True b -> b

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
  a /= a' = if a == a' then False else True

open Eq {{...}} public

instance
  eqVoid : Eq Void
  eqVoid ._==_ = λ ()

  eqUnit : Eq Unit
  eqUnit ._==_ unit unit = True

  eqBool : Eq Bool
  eqBool ._==_ = λ where
    True True -> True
    False False -> False
    _ _ -> False

  eqNat : Eq Nat
  eqNat ._==_ = Agda.Builtin.Nat._==_

  eqInt : Eq Int
  eqInt ._==_ = λ where
    (Pos m) (Pos n) -> m == n
    (NegSuc m) (NegSuc n) -> m == n
    _ _ -> False

  eqFloat : Eq Float
  eqFloat ._==_ = Agda.Builtin.Float.primFloatNumericalEquality

  eqChar : Eq Char
  eqChar ._==_ = Agda.Builtin.Char.primCharEquality

  eqString : Eq String
  eqString ._==_ = Agda.Builtin.String.primStringEquality

  eqEither : {{_ : Eq A}} {{_ : Eq B}} -> Eq (Either A B)
  eqEither ._==_ = λ where
    (Left a) (Left a') -> a == a'
    (Right b) (Right b') -> b == b'
    _ _ -> False

  eqTuple : {{_ : Eq A}} {{_ : Eq B}} -> Eq (Tuple A B)
  eqTuple ._==_ (a , b) (a' , b') = (a == a') && (b == b')

  eqMaybe : {{_ : Eq A}} -> Eq (Maybe A)
  eqMaybe ._==_ = λ where
    Nothing Nothing -> True
    (Just a) (Just a') -> a == a'
    _ _ -> False

  eqList : {{_ : Eq A}} -> Eq (List A)
  eqList ._==_ = λ where
    [] [] -> True
    (a :: as) (a' :: as') -> a == a' && as == as'
    _ _ -> False

  eqIdentity : {{_ : Eq A}} -> Eq (Identity A)
  eqIdentity ._==_ (Identity: a) (Identity: a') = a == a'

  eqConst : {{_ : Eq A}} -> Eq (Const A B)
  eqConst ._==_ (Const: a) (Const: a') = a == a'

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

  infixl 4 _<=_
  _<=_ : A -> A -> Bool
  a <= a' = if a < a' then True else if a == a' then True else False

  infixl 4 _>_
  _>_ : A -> A -> Bool
  _>_ = flip _<_

  infixl 4 _>=_
  _>=_ : A -> A -> Bool
  _>=_ = flip _<=_

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
  ordUnit ._<_ unit unit = False

  ordBool : Ord Bool
  ordBool ._<_ = λ where
    False True -> True
    _ _ -> False

  ordNat : Ord Nat
  ordNat ._<_ = Agda.Builtin.Nat._<_

  ordInt : Ord Int
  ordInt ._<_ = λ where
    (Pos m) (Pos n) -> m < n
    (NegSuc m) (NegSuc n) -> m > n
    (NegSuc _) (Pos _) -> True
    (Pos _) (NegSuc _) -> False

  ordFloat : Ord Float
  ordFloat ._<_ = Agda.Builtin.Float.primFloatNumericalLess

  ordChar : Ord Char
  ordChar ._<_ c c' = ord c < ord c'

  ordList : {{_ : Ord A}} -> Ord (List A)
  ordList ._<_ = λ where
    (a :: as) (a' :: as') -> a < a' || (a == a' && as < as')
    [] [] -> True
    _ _ -> False

  ordString : Ord String
  ordString ._<_ s s' with unpack s | unpack s'
  ... | (c :: cs) | (c' :: cs') = c < c' || (c == c' && cs < cs')
  ... | _ | _ = False

  ordTuple : {{_ : Ord A}} {{_ : Ord B}} -> Ord (Tuple A B)
  ordTuple ._<_ (a , b) (a' , b') = a < a' || (a == a' && b < b')

  ordMaybe : {{_ : Ord A}} -> Ord (Maybe A)
  ordMaybe ._<_ = λ where
    _ Nothing -> False
    Nothing _ -> True
    (Just a) (Just a') -> a < a'

  ordIdentity : {{_ : Ord A}} -> Ord (Identity A)
  ordIdentity ._<_ (Identity: a) (Identity: a') = a < a'

  ordConst : {{_ : Ord A}} -> Ord (Const A B)
  ordConst ._<_ (Const: a) (Const: a') = a < a'

--------------------------------------------------------------------------------
-- FromNat and FromNeg
--------------------------------------------------------------------------------

open import Agda.Builtin.FromNat public
  renaming (Number to FromNat)
  using (fromNat)

open import Agda.Builtin.FromNeg public
  renaming (Negative to FromNeg)
  using (fromNeg)

instance
  fromNatNat : FromNat Nat
  fromNatNat = record {
      Constraint = const Unit;
      fromNat = λ n -> n
    }

  fromNatInt : FromNat Int
  fromNatInt = record {
      Constraint = const Unit;
      fromNat = λ n -> Pos n
    }

  fromNegInt : FromNeg Int
  fromNegInt = record {
      Constraint = const Unit;
      fromNeg = λ n -> neg n
    }

  fromNegFloat : FromNeg Float
  fromNegFloat = record {
      Constraint = const Unit;
      fromNeg = λ x -> Agda.Builtin.Float.primFloatNegate (natToFloat x)
    }

--------------------------------------------------------------------------------
-- Arithmetic operations
--------------------------------------------------------------------------------

record Addition (A : Set) : Set where
  infixl 6 _+_
  field _+_ : A -> A -> A

open Addition {{...}} public

record Multiplication (A : Set) : Set where
  infixl 7 _*_
  field _*_ : A -> A -> A

open Multiplication {{...}} public

record Power (A : Set) : Set where
  infixr 10 _^_
  field _^_ : A -> Nat -> A

open Power {{...}} public

record Exponentiation (A : Set) : Set where
  infixr 8 _**_
  field _**_ : A -> A -> A

open Exponentiation {{...}} public

record Negation (A : Set) : Set where
  field -_ : A -> A

open Negation {{...}} public

record Subtraction (A : Set) : Set where
  infixl 6 _-_
  field _-_ : A -> A -> A

open Subtraction {{...}} public

record Division (A : Set) : Set where
  infixl 7 _/_
  field
    DivisionConstraint : A -> Set
    _/_ : (a a' : A) {{_ : DivisionConstraint a'}} -> A

open Division {{...}} public

record Modulus (A : Set) : Set where
  infixl 7 _%_
  field
    ModulusConstraint : A -> Set
    _%_ : (a a' : A) {{_ : ModulusConstraint a'}} -> A

open Modulus {{...}} public

record Signed (A : Set) : Set where
  field
    abs : A -> A
    signum : A -> A
open Signed {{...}} public

instance
  additionSet : Addition Set
  additionSet ._+_ = Either

  multiplicationSet : Multiplication Set
  multiplicationSet ._*_ = Tuple

  powerSet : Power Set
  powerSet ._^_ A = λ where
    0 -> Unit
    1 -> A
    (Suc n) -> A ^ n * A

  additionNat : Addition Nat
  additionNat ._+_ = Agda.Builtin.Nat._+_

  multiplicationNat : Multiplication Nat
  multiplicationNat ._*_ = Agda.Builtin.Nat._*_

  powerNat : Power Nat
  powerNat ._^_ a = λ where
    0 -> 1
    1 -> a
    (Suc n) -> a ^ n * a

  exponentiationNat : Exponentiation Nat
  exponentiationNat ._**_ = _^_

  subtractionNat : Subtraction Nat
  subtractionNat ._-_ = Agda.Builtin.Nat._-_

  divisionNat : Division Nat
  divisionNat .DivisionConstraint n = So (n > 0)
  divisionNat ._/_ m (Suc n) = divAux 0 n m n
    where divAux = Agda.Builtin.Nat.div-helper

  modulusNat : Modulus Nat
  modulusNat .ModulusConstraint n = So (n > 0)
  modulusNat ._%_ m (Suc n) = modAux 0 n m n
    where modAux = Agda.Builtin.Nat.mod-helper

  additionInt : Addition Int
  additionInt ._+_ = add
    where
      sub' : Nat -> Nat -> Int
      sub' m 0 = Pos m
      sub' 0 (Suc n) = NegSuc n
      sub' (Suc m) (Suc n) = sub' m n

      add : Int -> Int -> Int
      add (NegSuc m) (NegSuc n) = NegSuc (Suc (m + n))
      add (NegSuc m) (Pos n) = sub' n (Suc m)
      add (Pos m) (NegSuc n) = sub' m (Suc n)
      add (Pos m) (Pos n) = Pos (m + n)

  multiplicationInt : Multiplication Int
  multiplicationInt ._*_ = λ where
    (Pos n) (Pos m) -> Pos (n * m)
    (NegSuc n) (NegSuc m) -> Pos (Suc n * Suc m)
    (Pos n) (NegSuc m) -> neg (n * Suc m)
    (NegSuc n) (Pos m) -> neg (Suc n * m)

  powerInt : Power Int
  powerInt ._^_ a = λ where
    0 -> 1
    1 -> a
    (Suc n) -> a ^ n * a

  negationInt : Negation Int
  negationInt .-_ = λ where
    (Pos 0) -> Pos 0
    (Pos (Suc n)) -> NegSuc n
    (NegSuc n) -> Pos (Suc n)

  subtractionInt : Subtraction Int
  subtractionInt ._-_ m n = m + (- n)

  divisionInt : Division Int
  divisionInt .DivisionConstraint n = So (n > 0)
  divisionInt ._/_ x y with x | y
  ... | Pos m | Pos (Suc n) = Pos (m / Suc n)
  ... | NegSuc m | Pos (Suc n) = neg (Suc m / Suc n)
  ... | Pos m | NegSuc n = neg (m / Suc n)
  ... | NegSuc m | NegSuc n = Pos (Suc m / Suc n)

  modulusInt : Modulus Int
  modulusInt .ModulusConstraint n = So (n > 0)
  modulusInt ._%_ x y with x | y
  ... | Pos m | Pos (Suc n) = Pos (m % Suc n)
  ... | NegSuc m | Pos (Suc n) = neg (Suc m % Suc n)
  ... | Pos m | NegSuc n = Pos (m % Suc n)
  ... | NegSuc m | NegSuc n = neg (Suc m % Suc n)

  signedInt : Signed Int
  signedInt .abs = λ where
    (Pos n) -> Pos n
    (NegSuc n) -> Pos (Suc n)
  signedInt .signum = λ where
    (Pos 0) -> Pos 0
    (Pos (Suc _)) -> Pos 1
    (NegSuc _) -> NegSuc 0

  additionFloat : Addition Float
  additionFloat ._+_ = Agda.Builtin.Float.primFloatPlus

  multiplicationFloat : Multiplication Float
  multiplicationFloat ._*_ = Agda.Builtin.Float.primFloatTimes

  powerFloat : Power Float
  powerFloat ._^_ a = λ where
    0 -> 1.0
    1 -> a
    (Suc n) -> a ^ n * a

  exponentiationFloat : Exponentiation Float
  exponentiationFloat ._**_ x y = exp (y * log x)

  negationFloat : Negation Float
  negationFloat .-_ = Agda.Builtin.Float.primFloatNegate

  subtractionFloat : Subtraction Float
  subtractionFloat ._-_ = Agda.Builtin.Float.primFloatMinus

  divisionFloat : Division Float
  divisionFloat .DivisionConstraint = const Unit
  divisionFloat ._/_ x y = Agda.Builtin.Float.primFloatDiv x y

  signedFloat : Signed Float
  signedFloat .abs x = if x < 0.0 then - x else x
  signedFloat .signum x with compare x 0.0
  ... | EQ = 0.0
  ... | LT = -1.0
  ... | GT = 1.0

  additionFunction : {{_ : Addition B}} -> Addition (A -> B)
  additionFunction ._+_ f g x = f x + g x

  multiplicationFunction : {{_ : Multiplication B}} -> Multiplication (A -> B)
  multiplicationFunction ._*_ f g x = f x * g x

  negationFunction : {{_ : Negation B}} -> Negation (A -> B)
  negationFunction .-_ f x = - (f x)

  subtractionFunction : {{_ : Subtraction B}} -> Subtraction (A -> B)
  subtractionFunction ._-_ f g x = f x - g x

  powerFunction : Power (A -> A)
  powerFunction ._^_ f = λ where
    0 -> id
    1 -> f
    (Suc n) -> f ^ n ∘ f

--------------------------------------------------------------------------------
-- Semigroup
--------------------------------------------------------------------------------

record Semigroup (A : Set) : Set where
  infixr 5 _<>_
  field _<>_ : A -> A -> A

open Semigroup {{...}} public

-- For additive semigroups, monoids, etc.
record Sum (A : Set) : Set where
  constructor Sum:
  field getSum : A

open Sum public

-- For multiplicative semigroups, monoids, etc.
record Product (A : Set) : Set where
  constructor Product:
  field getProduct : A

open Product public

-- For dual semigroups, orders, etc.
record Dual (A : Set) : Set where
  constructor Dual:
  field getDual : A

open Dual public

-- Semigroup where x <> y = x
record First (A : Set) : Set where
  constructor First:
  field getFirst : A

open First public

-- Semigroup where x <> y = y
record Last (A : Set) : Set where
  constructor Last:
  field getLast : A

open Last public

-- For semigroups, monoids, etc. where x <> y = min x y
record Min (A : Set) : Set where
  constructor Min:
  field getMin : A

open Min public

-- For Semigroups, monoids, etc. where x <> y = max x y
record Max (A : Set) : Set where
  constructor Max:
  field getMax : A

open Max public

-- Bool semigroup where x <> y = x || y.
record Any : Set where
  constructor Any:
  field getAny : Bool

open Any public

-- Bool semigroup where x <> y = x && y.
record All : Set where
  constructor All:
  field getAll : Bool

open All public

instance
  semigroupDual : {{_ : Semigroup A}} -> Semigroup (Dual A)
  semigroupDual ._<>_ (Dual: a) (Dual: a') = Dual: (a' <> a)

  semigroupFirst : Semigroup (First A)
  semigroupFirst ._<>_ a _ = a

  semigroupLast : Semigroup (Last A)
  semigroupLast ._<>_ _ a = a

  semigroupMin : {{_ : Ord A}} -> Semigroup (Min A)
  semigroupMin ._<>_ (Min: a) (Min: a') = Min: (min a a')

  semigroupMax : {{_ : Ord A}} -> Semigroup (Max A)
  semigroupMax ._<>_ (Max: a) (Max: a') = Max: (max a a')

  semigroupAny : Semigroup Any
  semigroupAny ._<>_ (Any: b) (Any: b') = Any: (b || b')

  semigroupAll : Semigroup All
  semigroupAll ._<>_ (All: b) (All: b') = All: (b && b')

  semigroupVoid : Semigroup Void
  semigroupVoid ._<>_ = λ ()

  semigroupUnit : Semigroup Unit
  semigroupUnit ._<>_ unit unit = unit

  semigroupSumNat : Semigroup (Sum Nat)
  semigroupSumNat ._<>_ (Sum: m) (Sum: n) = Sum: (m + n)

  semigroupProductNat : Semigroup (Product Nat)
  semigroupProductNat ._<>_ (Product: x) (Product: y) = Product: (x * y)

  semigroupSumInt : Semigroup (Sum Int)
  semigroupSumInt ._<>_ (Sum: m) (Sum: n) = Sum: (m + n)

  semigroupProductInt : Semigroup (Product Int)
  semigroupProductInt ._<>_ (Product: x) (Product: y) = Product: (x * y)

  semigroupString : Semigroup String
  semigroupString ._<>_ = Agda.Builtin.String.primStringAppend

  semigroupFunction : {{_ : Semigroup B}} -> Semigroup (A -> B)
  semigroupFunction ._<>_ f g = λ a -> f a <> g a

  semigroupEither : {{_ : Semigroup A}} {{_ : Semigroup B}}
    -> Semigroup (Either A B)
  semigroupEither ._<>_ (Left _) b = b
  semigroupEither ._<>_ a _ = a

  semigroupTuple : {{_ : Semigroup A}} {{_ : Semigroup B}}
    -> Semigroup (Tuple A B)
  semigroupTuple ._<>_ (a , b) (a' , b') = (a <> a' , b <> b')

  semigroupMaybe : {{_ : Semigroup A}} -> Semigroup (Maybe A)
  semigroupMaybe ._<>_ = λ where
    Nothing m -> m
    m Nothing -> m
    (Just a) (Just a') -> Just (a <> a')

  semigroupList : Semigroup (List A)
  semigroupList ._<>_ as as' = listrec as' (λ x _ xs -> x :: xs) as

  semigroupIO : {{_ : Semigroup A}} -> Semigroup (IO A)
  semigroupIO ._<>_ x y = let _<*>_ = apIO; pure = pureIO in
    (| _<>_ x y |)

  semigroupIdentity : {{_ : Semigroup A}} -> Semigroup (Identity A)
  semigroupIdentity ._<>_ (Identity: a) (Identity: a') =
    Identity: (a <> a')

  semigroupConst : {{_ : Semigroup A}} -> Semigroup (Const A B)
  semigroupConst ._<>_ (Const: a) (Const: a') = Const: (a <> a')

  semigroupEndo : Semigroup (Endo A)
  semigroupEndo ._<>_ g f = Endo: (appEndo g ∘ appEndo f)

--------------------------------------------------------------------------------
-- Monoid
--------------------------------------------------------------------------------

record Monoid (A : Set) : Set where
  field
    overlap {{super}} : Semigroup A
    neutral : A

  when : Bool -> A -> A
  when True a = a
  when False _ = neutral

  unless : Bool -> A -> A
  unless True _ = neutral
  unless False a = a

open Monoid {{...}} public

instance
  monoidDual : {{_ : Monoid A}} -> Monoid (Dual A)
  monoidDual .neutral = Dual: neutral

  monoidFirst : {{_ : Monoid A}} -> Monoid (First A)
  monoidFirst .neutral = First: neutral

  monoidLast : {{_ : Monoid A}} -> Monoid (Last A)
  monoidLast .neutral = Last: neutral

  monoidUnit : Monoid Unit
  monoidUnit .neutral = unit

  monoidAll : Monoid All
  monoidAll .neutral = All: True

  monoidAny : Monoid Any
  monoidAny .neutral = Any: False

  monoidSumNat : Monoid (Sum Nat)
  monoidSumNat .neutral = Sum: 0

  monoidProductNat : Monoid (Product Nat)
  monoidProductNat .neutral = Product: (Suc 0)

  monoidSumInt : Monoid (Sum Int)
  monoidSumInt .neutral = Sum: 0

  monoidProductInt : Monoid (Product Int)
  monoidProductInt .neutral = Product: 1

  monoidString : Monoid String
  monoidString .neutral = ""

  monoidFunction : {{_ : Monoid B}} -> Monoid (A -> B)
  monoidFunction .neutral = const neutral

  monoidEndo : Monoid (Endo A)
  monoidEndo .neutral = Endo: id

  monoidMaybe : {{_ : Semigroup A}} -> Monoid (Maybe A)
  monoidMaybe .neutral = Nothing

  monoidList : Monoid (List A)
  monoidList .neutral = []

  monoidIO : {{_ : Monoid A}} -> Monoid (IO A)
  monoidIO .neutral = pureIO neutral

  monoidIdentity : {{_ : Monoid A}} -> Monoid (Identity A)
  monoidIdentity .neutral = Identity: neutral

  monoidConst : {{_ : Monoid A}} -> Monoid (Const A B)
  monoidConst .neutral = Const: neutral

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

  fromList : List A -> S
  fromList [] = nil
  fromList (a :: as) = cons a (fromList as)

  fromMaybe : Maybe A -> S
  fromMaybe Nothing = nil
  fromMaybe (Just a) = singleton a

  replicate : Nat -> A -> S
  replicate n a = applyN (cons a) n nil

open IsBuildable {{...}} public

Buildable : (Set -> Set) -> Set
Buildable F = forall {A} -> IsBuildable (F A) A

{-# TERMINATING #-}
unfoldr : {{_ : IsBuildable S A}} -> (B -> Maybe (Tuple A B)) -> B -> S
unfoldr f b with f b
... | Nothing = nil
... | (Just (a , b')) = cons a (unfoldr f b')

{-# TERMINATING #-}
unfoldl : {{_ : IsBuildable S A}} -> (B -> Maybe (Tuple B A)) -> B -> S
unfoldl f b with f b
... | Nothing = nil
... | (Just (b' , a)) = snoc (unfoldl f b') a

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
F ~> G  = forall {A} -> F A -> G A

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
  void = map (const unit)

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
  profunctorFunction : Profunctor Function
  profunctorFunction .dimap f g h = g ∘ h ∘ f

  bifunctorEither : Bifunctor Either
  bifunctorEither .bimap f g = either (Left ∘ f) (Right ∘ g)

  functorEither : Functor (Either A)
  functorEither .map = second

  bifunctorTuple : Bifunctor Tuple
  bifunctorTuple .bimap f g = tuple (f ∘ fst) (g ∘ snd)

  functorTuple : Functor (Tuple A)
  functorTuple .map = second

  functorMaybe : Functor Maybe
  functorMaybe .map f = λ where
    Nothing -> Nothing
    (Just a) -> Just (f a)

  functorList : Functor List
  functorList .map f = listrec [] λ a _ bs -> f a :: bs

  functorIO : Functor IO
  functorIO .map = mapIO

  functorIdentity : Functor Identity
  functorIdentity .map f = Identity: ∘ f ∘ runIdentity

  bifunctorConst : Bifunctor Const
  bifunctorConst .bimap f g = Const: ∘ f ∘ getConst

  functorConst : Functor (Const A)
  functorConst .map = second

  contravariantConst : Contravariant (Const A)
  contravariantConst .contramap f = Const: ∘ getConst

  functorSum : Functor Sum
  functorSum .map f = Sum: ∘ f ∘ getSum

  functorProduct : Functor Product
  functorProduct .map f = Product: ∘ f ∘ getProduct

  functorDual : Functor Dual
  functorDual .map f = Dual: ∘ f ∘ getDual

  functorFirst : Functor First
  functorFirst .map f = First: ∘ f ∘ getFirst

  functorLast : Functor Last
  functorLast .map f = Last: ∘ f ∘ getLast

  functorMin : Functor Min
  functorMin .map f = Min: ∘ f ∘ getMin

  functorMax : Functor Max
  functorMax .map f = Max: ∘ f ∘ getMax

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

  replicateA : {{_ : IsBuildable S A}} -> Nat -> F A -> F S
  replicateA {S} {A} n0 f = loop n0
    where
      loop : Nat -> F S
      loop 0 = pure nil
      loop (Suc n) = (| cons f (loop n) |)

  replicateA! : Nat -> F A -> F Unit
  replicateA! n0 f = loop n0
    where
      loop : Nat -> F Unit
      loop 0 = pure unit
      loop (Suc n) = f *> loop n

open Applicative {{...}} public

instance
  applicativeEither : Applicative (Either A)
  applicativeEither .pure = Right
  applicativeEither ._<*>_ = λ where
    (Left a) _ -> Left a
    (Right f) -> map f

  applicativeMaybe : Applicative Maybe
  applicativeMaybe .pure = Just
  applicativeMaybe ._<*>_ = λ where
    (Just f) -> map f
    Nothing _ -> Nothing

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
  applicativeIdentity .pure = Identity:
  applicativeIdentity ._<*>_ = map ∘ runIdentity

  applicativeConst : {{_ : Monoid A}} -> Applicative (Const A)
  applicativeConst .pure _ = Const: neutral
  applicativeConst ._<*>_ (Const: f) (Const: a) = Const: (f <> a)

  applicativeSum : Applicative Sum
  applicativeSum .pure = Sum:
  applicativeSum ._<*>_ (Sum: f) (Sum: x) = Sum: (f x)

  applicativeProduct : Applicative Product
  applicativeProduct .pure = Product:
  applicativeProduct ._<*>_ (Product: f) (Product: x) = Product: (f x)

  applicativeDual : Applicative Dual
  applicativeDual .pure = Dual:
  applicativeDual ._<*>_ (Dual: f) (Dual: x) = Dual: (f x)

  applicativeFirst : Applicative First
  applicativeFirst .pure = First:
  applicativeFirst ._<*>_ (First: f) (First: x) = First: (f x)

  applicativeLast : Applicative Last
  applicativeLast .pure = Last:
  applicativeLast ._<*>_ (Last: f) (Last: x) = Last: (f x)

  applicativeMin : Applicative Min
  applicativeMin .pure = Min:
  applicativeMin ._<*>_ (Min: f) (Min: x) = Min: (f x)

  applicativeMax : Applicative Max
  applicativeMax .pure = Max:
  applicativeMax ._<*>_ (Max: f) (Max: x) = Max: (f x)

--------------------------------------------------------------------------------
-- Alternative
--------------------------------------------------------------------------------

record Alternative (F : Set -> Set) : Set where
  infixl 3 _<|>_
  field
    overlap {{super}} : Applicative F
    _<|>_ : F A -> F A -> F A
    empty : F A

  guard : Bool -> F Unit
  guard True = pure unit
  guard False = empty

open Alternative {{...}} public

instance
  alternativeMaybe : Alternative Maybe
  alternativeMaybe .empty = Nothing
  alternativeMaybe ._<|>_ = λ where
    Nothing r -> r
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

  join : M (M A) -> M A
  join = _>>= id

  infixl 1 _>>_
  _>>_ : M A -> M B -> M B
  _>>_ = _*>_

open Monad {{...}} public

return : forall {A M} {{_ : Monad M}} -> A -> M A
return = pure

instance
  monadEither : Monad (Either A)
  monadEither ._>>=_ = λ where
    (Left a) _ -> Left a
    (Right x) k -> k x

  monadMaybe : Monad Maybe
  monadMaybe ._>>=_ = λ where
    Nothing _ -> Nothing
    (Just x) k -> k x

  monadList : Monad List
  monadList ._>>=_ = λ where
    [] k -> []
    (x :: xs) k -> k x ++ (xs >>= k)

  monadIO : Monad IO
  monadIO ._>>=_ = bindIO

  monadIdentity : Monad Identity
  monadIdentity ._>>=_ (Identity: x) k = k x

  monadSum : Monad Sum
  monadSum ._>>=_ (Sum: x) k = k x

  monadProduct : Monad Product
  monadProduct ._>>=_ (Product: x) k = k x

  monadDual : Monad Dual
  monadDual ._>>=_ (Dual: x) k = k x

  monadFirst : Monad First
  monadFirst ._>>=_ (First: x) k = k x

  monadLast : Monad Last
  monadLast ._>>=_ (Last: x) k = k x

  monadMin : Monad Min
  monadMin ._>>=_ (Min: x) k = k x

  monadMax : Monad Max
  monadMax ._>>=_ (Max: x) k = k x

--------------------------------------------------------------------------------
-- IsFoldable, Foldable
--------------------------------------------------------------------------------

record IsFoldable (S A : Set) : Set where
  field foldMap : {{_ : Monoid B}} -> (A -> B) -> S -> B

  fold : {{_ : Monoid A}} -> S -> A
  fold = foldMap id

  foldr : (A -> B -> B) -> B -> S -> B
  foldr f b as = appEndo (foldMap (Endo: ∘ f) as) b

  foldl : (B -> A -> B) -> B -> S -> B
  foldl f b as =
    (appEndo ∘ getDual) (foldMap (Dual: ∘ Endo: ∘ flip f) as) b

  foldrM : {{_ : Monad M}} -> (A -> B -> M B) -> B -> S -> M B
  foldrM f b as = let g k a b' = f a b' >>= k in
    foldl g return as b

  foldlM : {{_ : Monad M}} -> (B -> A -> M B) -> B -> S -> M B
  foldlM f b as = let g a k b' = f b' a >>= k in
    foldr g return as b

  toList : S -> List A
  toList = foldMap [_]

  count : S -> Nat
  count = getSum ∘ foldMap (const $ Sum: (Suc 0))

  all : (A -> Bool) -> S -> Bool
  all p = getAll ∘ foldMap (All: ∘ p)

  any : (A -> Bool) -> S -> Bool
  any p = getAny ∘ foldMap (Any: ∘ p)

  notNull : S -> Bool
  notNull = any (const True)

  Nonempty : S -> Set
  Nonempty = So ∘ notNull

  null : S -> Bool
  null = not ∘ notNull

  sum : {{ _ : Monoid (Sum A)}} -> S -> A
  sum = getSum ∘ foldMap Sum:

  product : {{ _ : Monoid (Product A)}} -> S -> A
  product = getProduct ∘ foldMap Product:

  find : (A -> Bool) -> S -> Maybe A
  find p = leftToMaybe ∘
    foldlM (λ _ a ->  if p a then Left a else Right unit) unit

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
Foldable F = forall {A} -> IsFoldable (F A) A

instance
  isFoldableNatUnit : IsFoldable Nat Unit
  isFoldableNatUnit .foldMap b 0 = neutral
  isFoldableNatUnit .foldMap b (Suc n) = b unit <> foldMap b n

  foldableEither : Foldable (Either A)
  foldableEither .foldMap _ (Left _) = neutral
  foldableEither .foldMap f (Right x) = f x

  foldableTuple : Foldable (Tuple A)
  foldableTuple .foldMap f (_ , x) = f x

  foldableMaybe : Foldable Maybe
  foldableMaybe .foldMap = maybe neutral

  foldableList : Foldable List
  foldableList .foldMap f = listrec neutral λ x _ y -> f x <> y

  isFoldableStringChar : IsFoldable String Char
  isFoldableStringChar .foldMap f = foldMap f ∘ unpack

--------------------------------------------------------------------------------
-- IsFoldable1, Foldable1
--------------------------------------------------------------------------------

record IsFoldable1 (S A : Set) : Set where
  field {{isFoldable}} : IsFoldable S A

  foldMap1 : {{_ : Semigroup B}}
    -> (A -> B) -> (s : S) {{_ : Nonempty s}} -> B
  foldMap1 f s = fromJust (foldMap (Just ∘ f) s) {{believeMe}}

  fold1 : {{_ : Semigroup A}} (s : S) {{_ : Nonempty s}} -> A
  fold1 s = fromJust (foldMap Just s) {{believeMe}}

  foldr1 : (A -> A -> A) -> (s : S) {{_ : Nonempty s}} -> A
  foldr1 f s = fromJust (foldr g Nothing s) {{believeMe}}
    where
      g : A -> Maybe A -> Maybe A
      g a Nothing = Just a
      g a (Just a') = Just (f a a')

  foldl1 : (A -> A -> A) -> (s : S) {{_ : Nonempty s}} -> A
  foldl1 f s = fromJust (foldl g Nothing s) {{believeMe}}
    where
      g : Maybe A -> A -> Maybe A
      g Nothing a = Just a
      g (Just a) a' = Just (f a a')

  module _ {{_ : Ord A}} where

    minimum : (s : S) {{_ : Nonempty s}} -> A
    minimum = foldr1 min

    maximum : (s : S) {{_ : Nonempty s}} -> A
    maximum = foldr1 max

open IsFoldable1 {{...}} public

Foldable1 : (Set -> Set) -> Set
Foldable1 F = forall {A} -> IsFoldable1 (F A) A

instance
  isFoldable1 : {{_ : IsFoldable S A}} -> IsFoldable1 S A
  isFoldable1 = record {}

--------------------------------------------------------------------------------
-- Traversable
--------------------------------------------------------------------------------

private
  record StateL (S A : Set) : Set where
    constructor stateL:
    field runStateL : S -> Tuple S A

  open StateL

  record StateR (S A : Set) : Set where
    constructor stateR:
    field runStateR : S -> Tuple S A

  open StateR

  instance
    functorStateL : Functor (StateL S)
    functorStateL .map f (stateL: t) = stateL: λ s0 ->
      let (s1 , x) = t s0 in (s1 , f x)

    functorStateR : Functor (StateR S)
    functorStateR .map f (stateR: t) = stateR: λ s0 ->
      let (s1 , x) = t s0 in (s1 , f x)

    applicativeStateL : Applicative (StateL S)
    applicativeStateL .pure x = stateL: λ s -> (s , x)
    applicativeStateL ._<*>_ (stateL: f) (stateL: t) = stateL: λ s0 ->
      let (s1 , f') = f s0; (s2 , x) = t s1 in (s2 , f' x)

    applicativeStateR : Applicative (StateR S)
    applicativeStateR .pure x = stateR: λ s -> (s , x)
    applicativeStateR ._<*>_ (stateR: f) (stateR: t) = stateR: λ s0 ->
      let (s1 , x) = t s0; (s2 , f') = f s1 in (s2 , f' x)

record Traversable (T : Set -> Set) : Set where
  field
    {{superFunctor}} : Functor T
    {{superFoldable}} : Foldable T
    traverse : {{_ : Applicative F}} -> (A -> F B) -> T A -> F (T B)

  sequence : {{_ : Applicative F}} -> T (F A) -> F (T A)
  sequence = traverse id

  for : {{_ : Applicative F}} -> T A -> (A -> F B) -> F (T B)
  for = flip traverse

  mapAccumL : (A -> B -> Tuple A C) -> A -> T B -> Tuple A (T C)
  mapAccumL f a xs = runStateL (traverse (stateL: ∘ flip f) xs) a

  mapAccumR : (A -> B -> Tuple A C) -> A -> T B -> Tuple A (T C)
  mapAccumR f a xs = runStateR (traverse (stateR: ∘ flip f) xs) a

  scanl : {{_ : Buildable T}} -> (B -> A -> B) -> B -> T A -> T B
  scanl f b0 xs = uncurry (flip snoc) (mapAccumL (λ b a -> (f b a , b)) b0 xs)

  scanr : {{_ : Buildable T}} -> (A -> B -> B) -> B -> T A -> T B
  scanr f b0 xs = uncurry cons (mapAccumR (λ b a -> (f a b , b)) b0 xs)

open Traversable {{...}} public

instance
  traversableEither : Traversable (Either A)
  traversableEither .traverse f = λ where
    (Left a) -> pure (Left a)
    (Right x) -> map Right (f x)

  traversableTuple : Traversable (Tuple A)
  traversableTuple .traverse f (a , x) = map (a ,_) (f x)

  traversableMaybe : Traversable Maybe
  traversableMaybe .traverse f = λ where
    Nothing -> pure Nothing
    (Just x) -> map Just (f x)

  traversableList : Traversable List
  traversableList .traverse f = listrec (pure []) λ where
    x _ ys -> (| _::_ (f x) ys |)

--------------------------------------------------------------------------------
-- Show
--------------------------------------------------------------------------------

record Show (A : Set) : Set where
  field show : A -> String

  print : A -> IO Unit
  print a = putStrLn (show a)

open Show {{...}} public

instance
  showVoid : Show Void
  showVoid .show ()

  showUnit : Show Unit
  showUnit .show unit = "unit"

  showBool : Show Bool
  showBool .show True = "True"
  showBool .show False = "False"

  showNat : Show Nat
  showNat .show = Agda.Builtin.String.primShowNat

  showInt : Show Int
  showInt .show = Agda.Builtin.Int.primShowInteger

  showFloat : Show Float
  showFloat .show = Agda.Builtin.Float.primShowFloat

  showChar : Show Char
  showChar .show = Agda.Builtin.String.primShowChar

  showString : Show String
  showString .show = Agda.Builtin.String.primShowString

  showTuple : {{_ : Show A}} {{_ : Show B}} -> Show (Tuple A B)
  showTuple .show (a , b) = "(" ++ show a ++ " , " ++ show b ++ ")"

  showEither : {{_ : Show A}} {{_ : Show B}} -> Show (Either A B)
  showEither .show = λ where
    (Left a) -> "(Left " ++ show a ++ ")"
    (Right b) -> "(Right " ++ show b ++ ")"

  showMaybe : {{_ : Show A}} -> Show (Maybe A)
  showMaybe .show = λ where
    (Just a) -> "(Just " ++ show a ++ ")"
    Nothing -> "Nothing"

  showList : {{_ : Show A}} -> Show (List A)
  showList .show [] = "[]"
  showList .show as = "[ " ++ show' as ++ " ]"
    where
      show' : {{_ : Show A}} -> List A -> String
      show' [] = ""
      show' (a :: []) = show a
      show' (a :: as) = show a ++ " , " ++ show' as

  showIdentity : {{_ : Show A}} -> Show (Identity A)
  showIdentity .show (Identity: a) = "(Identity: " ++ show a ++ ")"

  showConst : {{_ : Show A}} -> Show (Const A B)
  showConst .show (Const: a) = "(Const: " ++ show a ++ ")"

  showSum : {{_ : Show A}} -> Show (Sum A)
  showSum .show (Sum: a) = "(Sum: " ++ show a ++ ")"

  showProduct : {{_ : Show A}} -> Show (Product A)
  showProduct .show (Product: a) = "(Product: " ++ show a ++ ")"

  showDual : {{_ : Show A}} -> Show (Dual A)
  showDual .show (Dual: a) = "(Dual: " ++ show a ++ ")"

  showFirst : {{_ : Show A}} -> Show (First A)
  showFirst .show (First: a) = "(First: " ++ show a ++ ")"

  showLast : {{_ : Show A}} -> Show (Last A)
  showLast .show (Last: a) = "(Last: " ++ show a ++ ")"

  showMin : {{_ : Show A}} -> Show (Min A)
  showMin .show (Min: a) = "(Min: " ++ show a ++ ")"

  showMax : {{_ : Show A}} -> Show (Max A)
  showMax .show (Max: a) = "(Max: " ++ show a ++ ")"

  showAny : Show Any
  showAny .show (Any: a) = "(Any: " ++ show a ++ ")"

  showAll : Show All
  showAll .show (All: a) = "(All: " ++ show a ++ ")"
