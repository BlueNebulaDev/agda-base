module Test.QC where

open import Prelude

open import Data.Ix
open import Data.List as List using ()
open import Data.Stream as Stream using (Stream)
open import Data.String as String using ()
open import System.Random

private variable a b g : Set

--------------------------------------------------------------------------------
-- Gen
--------------------------------------------------------------------------------

record Gen (a : Set) : Set where
  constructor Gen:
  field unGen : StdGen -> Nat -> a

instance
  functorGen : Functor Gen
  functorGen .map f (Gen: x) = Gen: λ r n -> f (x r n)

  applicativeGen : Applicative Gen
  applicativeGen .pure x = Gen: λ _ _ -> x
  applicativeGen ._<*>_ (Gen: f) (Gen: x) = Gen: λ r n ->
    let (r1 , r2) = split r in f r1 n (x r2 n)

  monadGen : Monad Gen
  monadGen ._>>=_ (Gen: m) k = Gen: λ r n ->
    let (r1 , r2) = split r; Gen: m' = k (m r1 n) in m' r2 n

--------------------------------------------------------------------------------
-- Gen combinators
--------------------------------------------------------------------------------

variant : Nat -> Gen a -> Gen a
variant v (Gen: m) =
    Gen: λ r n -> m (Stream.at (Suc v) (rands r)) n
  where
    rands : {{_ : RandomGen g}} -> g -> Stream g
    rands g = Stream.unfold split g

generate' : Nat -> StdGen -> Gen a -> a
generate' n rnd (Gen: m) = let (size , rnd') = randomR (0 , n) rnd in
  m rnd' size

sized : (Nat -> Gen a) -> Gen a
sized f = Gen: λ r n -> let Gen: m = f n in m r n

getSize : Gen Nat
getSize = sized pure

resize : Nat -> Gen a -> Gen a
resize n (Gen: g) = Gen: λ r _ -> g r n

scale : (Nat -> Nat) -> Gen a -> Gen a
scale f g = sized (λ n -> resize (f n) g)

choose : {{_ : RandomR a}} -> a * a -> Gen a
choose rng = Gen: λ r _ -> let (x , _) = randomR rng r in x

chooseAny : {{_ : Random a}} -> Gen a
chooseAny = Gen: λ r _ -> let (x , _) = random r in x

generate : Gen a -> IO a
generate (Gen: g) = do
  r <- newStdGen
  return (g r 30)

sample' : Gen a -> IO (List a)
sample' g = traverse generate $ do
  n <- 0 :: range (2 , 20)
  return (resize n g)

sample : {{_ : Show a}} -> Gen a -> IO Unit
sample g = do
  cases <- sample' g
  traverse! print cases

oneof : (gs : List (Gen a)) {{_ : Nonempty gs}} -> Gen a
oneof gs = do
  n <- choose (0 , count gs - 1)
  fromJust (List.at n gs) {{believeMe}}

frequency : (xs : List (Nat * Gen a)) {{_ : Assert $ sum (map fst xs) > 0}}
  -> Gen a
frequency {a} xs = choose (1 , tot) >>= (λ x -> pick x xs)
  where
    tot = sum (map fst xs)

    pick : Nat -> List (Nat * Gen a) -> Gen a
    pick n ((k , y) :: ys) = if n <= k then y else pick (n - k) ys
    pick n [] = undefined -- No worries. We'll never see this case.

elements : (xs : List a) {{_ : Nonempty xs}} -> Gen a
elements xs = map
  (λ n -> fromJust (List.at n xs) {{believeMe}})
  (choose {Nat} (0 , List.length xs - 1))

vectorOf : Nat -> Gen a -> Gen (List a)
vectorOf = replicateA

listOf : Gen a -> Gen (List a)
listOf gen = sized λ n -> do
  k <- choose (0 , n)
  vectorOf k gen

sublistOf : List a -> Gen (List a)
sublistOf xs = List.filterA (λ _ -> map (_== 0) $ choose {Nat} (0 , 1)) xs

shuffle : List a -> Gen (List a)
shuffle xs = do
  ns <- vectorOf (List.length xs) (choose {Nat} (0 , 2 ^ 32))
  return (map snd (List.sortBy (comparing fst) (List.zip ns xs)))

promote : (a -> Gen b) -> Gen (a -> b)
promote f = Gen: λ r n a -> let (Gen: m) = f a in m r n

--------------------------------------------------------------------------------
-- Arbitrary & Coarbitrary
--------------------------------------------------------------------------------

record Arbitrary (a : Set) : Set where
  field arbitrary : Gen a

open Arbitrary {{...}} public

record Coarbitrary (a : Set) : Set where
  field coarbitrary : a -> Gen b -> Gen b

open Coarbitrary {{...}} public

instance
  arbitraryBool : Arbitrary Bool
  arbitraryBool .arbitrary = elements (True :: False :: [])

  arbitraryNat : Arbitrary Nat
  arbitraryNat .arbitrary = sized λ n -> choose (0 , n)

  arbitraryInt : Arbitrary Int
  arbitraryInt .arbitrary = sized λ where
    0 -> choose (0 , 0)
    (Suc n) -> choose (NegSuc n , Pos (Suc n))

  arbitraryTuple : {{_ : Arbitrary a}} {{_ : Arbitrary b}} -> Arbitrary (a * b)
  arbitraryTuple .arbitrary = (| _,_ arbitrary arbitrary |)

  arbitraryList : {{_ : Arbitrary a}} -> Arbitrary (List a)
  arbitraryList .arbitrary = sized λ n -> do
    m <- choose (0 , n)
    vectorOf m arbitrary

  coarbitraryBool : Coarbitrary Bool
  coarbitraryBool .coarbitrary b = variant (if b then 0 else 1)

  coarbitraryTuple : {{_ : Coarbitrary a}} {{_ : Coarbitrary b}}
    -> Coarbitrary (a * b)
  coarbitraryTuple .coarbitrary (a , b) = coarbitrary a ∘ coarbitrary b

  coarbitraryList : {{_ : Coarbitrary a}} -> Coarbitrary (List a)
  coarbitraryList .coarbitrary [] = variant 0
  coarbitraryList .coarbitrary (a :: as) =
    variant 1 ∘ coarbitrary a ∘ coarbitrary as

  coarbitraryFunction : {{_ : Arbitrary a}} {{_ : Coarbitrary b}}
    -> Coarbitrary (a -> b)
  coarbitraryFunction .coarbitrary f gen =
    arbitrary >>= (flip coarbitrary gen ∘ f)

  arbitraryFunction : {{_ : Coarbitrary a}} {{_ : Arbitrary b}}
    -> Arbitrary (a -> b)
  arbitraryFunction .arbitrary = promote (flip coarbitrary arbitrary)

--------------------------------------------------------------------------------
-- Result & Property
--------------------------------------------------------------------------------

record Result : Set where
  field
    ok : Maybe Bool
    stamp : List String
    arguments : List String

record Property : Set where
  constructor property:
  field result : Gen Result

none : Result
none = record { ok = Nothing; stamp = []; arguments = [] }

result : Result -> Property
result res = property: (return res)

--------------------------------------------------------------------------------
-- Testable
--------------------------------------------------------------------------------

record Testable (a : Set) : Set where
  field property : a -> Property

open Testable {{...}}

evaluate : {{_ : Testable a}} -> a -> Gen Result
evaluate a = let (property: gen) = property a in gen

forAll : {{_ : Show a}} {{_ : Testable b}} -> Gen a -> (a -> b) -> Property
forAll gen body = property: do
  a <- gen
  res <- evaluate (body a)
  return (record res { arguments = show a :: Result.arguments res })

infixr 0 _==>_
_==>_ : {{_ : Testable a}} -> Bool -> a -> Property
True ==> a = property a
False ==> a = result none

label : {{_ : Testable a}} -> String -> a -> Property
label s a = property: (add <$> evaluate a)
  where
    add : Result -> Result
    add res = record res { stamp = s :: Result.stamp res }

classify : {{_ : Testable a}} -> Bool -> String -> a -> Property
classify True name = label name
classify False _ = property

collect : {{_ : Show a}} {{_ : Testable b}} -> a -> b -> Property
collect v = label (show v)

instance
  testableBool : Testable Bool
  testableBool .property b = result (record none { ok = Just b })

  testableProperty : Testable Property
  testableProperty .property prop = prop

  testableFunction : {{_ : Arbitrary a}} {{_ : Show a}} {{_ : Testable b}}
    -> Testable (a -> b)
  testableFunction .property f = forAll arbitrary f

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

record Config : Set where
  field
    maxTest : Nat
    maxFail : Nat
    size : Nat -> Nat
    every : Nat -> List String -> String

quick : Config
quick = record {
    maxTest = 100;
    maxFail = 1000;
    size = λ n -> n / 2 + 3;
    every = λ n args ->
      let s = show n in
      s ++ pack (replicate (String.length s) '\b')
  }

verbose : Config
verbose = record quick {
    every = λ n args -> show n ++ ":\n" ++ String.unlines args
  }

--------------------------------------------------------------------------------
-- check, quickCheck & verboseCheck
--------------------------------------------------------------------------------

private
  done : String -> Nat -> List (List String) -> IO Unit
  done mesg ntest stamps =
      do putStr (mesg ++ " " ++ show ntest ++ " tests" ++ table)
    where
      display : List String -> String
      display [] = ".\n"
      display [ x ] = " (" ++ x ++ ").\n"
      display xs = ".\n" ++ String.unlines (map (_++ ".") xs)

      pairLength : List (List String) -> Nat * List String
      pairLength [] = (0 , [])
      pairLength xss@(xs :: _) = (List.length xss , xs)

      percentage : Nat -> Nat -> String
      percentage n 0 = undefined -- No worries; we'll never use this case
      percentage n m@(Suc _) = show ((100 * n) / m) ++ "%"

      entry : Nat * (List String) -> String
      entry (n , s) = percentage n ntest
        ++ " "
        ++ String.concat (List.intersperse ", " s)

      table : String
      table = display
        ∘ map entry
        ∘ List.reverse
        ∘ List.sort
        ∘ map pairLength
        ∘ List.group
        ∘ List.sort
        ∘ List.filter (not ∘ null)
        $ stamps

  {-# TERMINATING #-}
  tests : Config -> Gen Result -> StdGen -> Nat -> Nat
    -> List (List String) -> IO Unit
  tests config gen rnd0 ntest nfail stamps =
    if ntest == Config.maxTest config
    then (do done "OK, passed" ntest stamps)
    else if nfail == Config.maxFail config
    then (do done "Arguments exhausted after" ntest stamps)
    else (
      let
        (rnd1 , rnd2) = split rnd0
        result = generate' (Config.size config ntest) rnd2 gen
      in do
        putStr (Config.every config ntest (Result.arguments result))
        case Result.ok result of λ where
          Nothing -> tests
            config gen rnd1 ntest (nfail + 1) stamps
          (Just True) -> tests
            config gen rnd1 (ntest + 1) nfail (Result.stamp result :: stamps)
          (Just False) -> putStr ("Falsifiable, after "
            ++ show ntest
            ++ " tests:\n"
            ++ String.unlines (Result.arguments result))
      )

check : {{_ : Testable a}} -> Config -> a -> IO Unit
check config a = do
  rnd <- newStdGen
  tests config (evaluate a) rnd 0 0 []

quickCheck : {{_ : Testable a}} -> a -> IO Unit
quickCheck = check quick

verboseCheck : {{_ : Testable a}} -> a -> IO Unit
verboseCheck = check verbose
