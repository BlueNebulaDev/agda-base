{-# OPTIONS --type-in-type #-}

module Test.Gen where

open import Prelude

open import Data.Bits
open import Data.List
open import Data.Stream as Stream using (Stream)
open import System.Random public

private variable A G : Set

record Gen (A : Set) : Set where
  constructor gen:
  field unGen : StdGen -> Nat -> A

instance
  functorGen : Functor Gen
  functorGen .map f (gen: h) = gen: \ r n -> f (h r n)

  applicativeGen : Applicative Gen
  applicativeGen .pure x = gen: \ _ _ -> x
  applicativeGen ._<*>_ (gen: f) (gen: x) = gen: \ r n -> f r n (x r n)

  monadGen : Monad Gen
  monadGen ._>>=_ (gen: m) k = gen: \ r n ->
    case splitGen r of \ where
      (r1 , r2) -> let gen: m' = k (m r1 n) in m' r2 n

variant : Nat -> Gen A -> Gen A
variant v (gen: m) =
    gen: \ r n -> m (Stream.at (suc v) (rands r)) n
  where
    rands : {{_ : RandomGen G}} -> G -> Stream G
    rands g = Stream.generate splitGen g

sized : (Nat -> Gen A) -> Gen A
sized f = gen: \ r n -> let gen: m = f n in m r n

getSize : Gen Nat
getSize = sized pure

resize : Nat -> Gen A -> Gen A
resize n (gen: g) = gen: \ r _ -> g r n

scale : (Nat -> Nat) -> Gen A -> Gen A
scale f g = sized (\ n -> resize (f n) g)

choose : {{_ : RandomR A}} -> A * A -> Gen A
choose rng = gen: \ r _ -> let (x , _) = randomR rng r in x

chooseAny : {{_ : Random A}} -> Gen A
chooseAny = gen: \ r _ -> let (x , _) = random r in x

generate : Gen A -> IO A
generate (gen: g) = do
  r <- newStdGen
  return (g r 30)

sample' : Gen A -> IO (List A)
sample' g = traverse generate $ do
  n <- 0 :: (range 2 20)
  return (resize n g)

sample : {{_ : Show A}} -> Gen A -> IO Unit
sample g = do
  cases <- sample' g
  traverse! print cases

oneof : (gs : List (Gen A)) {{_ : Nonempty gs}} -> Gen A
oneof gs = do
  n <- choose (0 , count gs - 1)
  fromJust (at n gs) {{believeMe}}

frequency : (xs : List (Nat * Gen A)) {{_ : So $ sum (map fst xs) > 0}}
  -> Gen A
frequency {A} xs = choose (1 , tot) >>= (\ x -> pick x xs)
  where
    tot = sum (map fst xs)

    pick : Nat -> List (Nat * Gen A) -> Gen A
    pick n ((k , y) :: ys) = if n <= k then y else pick (n - k) ys
    pick n [] = undefined -- No worries. We'll never see this case.

elements : (xs : List A) {{_ : Nonempty xs}} -> Gen A
elements xs = map
  (\ n -> fromJust (at n xs) {{believeMe}})
  (choose {Nat} (0 , length xs - 1))

vectorOf : Nat -> Gen A -> Gen (List A)
vectorOf = replicateA

listOf : Gen A -> Gen (List A)
listOf gen = sized \ n -> do
  k <- choose (0 , n)
  vectorOf k gen

sublistOf : List A -> Gen (List A)
sublistOf xs = filterA (\ _ -> map (_== 0) $ choose {Nat} (0 , 1)) xs

shuffle : List A -> Gen (List A)
shuffle xs = do
  ns <- vectorOf (length xs) (choose {Nat} (0 , 2 ^ 32))
  return (map snd (sortBy (comparing fst) (zip ns xs)))
