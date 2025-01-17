-- https://aaronlevin.ca/post/136494428283/extensible-effect-stacks-in-the-van-laarhoven-free

-------------------------------------------------------------------------------
-- Imports
-------------------------------------------------------------------------------

open import Prelude

open import Data.Bytes
open import Data.Functor.Product.Nary
open import Data.List.Elem
open import Control.Concurrent
open import Control.Exception
open import Control.Monad.Free.VL
open import System.IO
open import System.Random as R using ()

-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------

variable
  a : Set
  fs : List ((Set -> Set) -> Set)

Url : Set
Url = String

-------------------------------------------------------------------------------
-- Postulates
-------------------------------------------------------------------------------

postulate
  RequestBody : Set
  Response : Set -> Set
  HttpException : Set
  instance Exception-HttpException : Exception HttpException
  get : Url -> IO (Response Bytes)
  post : Url -> RequestBody -> IO (Response Bytes)

-------------------------------------------------------------------------------
-- Effects
-------------------------------------------------------------------------------

record Http (m : Set -> Set) : Set where
  field
    getHttpEff : Url -> m (Either Nat (Response Bytes))
    postHttpEff : Url -> RequestBody -> m (Either Nat (Response Bytes))

open Http

record Logging (m : Set -> Set) : Set where
  field logEff : String -> m Unit

open Logging

record Random (m : Set -> Set) : Set where
  field getRandEff : m Nat

open Random

record Suspend (m : Set -> Set) : Set where
  field suspendEff : Nat -> m Unit

open Suspend

-------------------------------------------------------------------------------
-- Smart constructors
-------------------------------------------------------------------------------

getHttp : {{Elem Http fs}}
  -> Url -> Free (ProductN fs) (Either Nat (Response Bytes))
getHttp {{elem}} url = liftFree \ prod -> getHttpEff (project elem prod) url

postHttp : {{Elem Http fs}}
  -> Url -> RequestBody -> Free (ProductN fs) (Either Nat (Response Bytes))
postHttp {{elem}} url body = liftFree \ prod -> postHttpEff (project elem prod) url body

logMsg : {{Elem Logging fs}} -> String -> Free (ProductN fs) Unit
logMsg {{elem}} msg = liftFree \ prod -> logEff (project elem prod) msg

getRand : {{Elem Random fs}} -> Free (ProductN fs) Nat
getRand {{elem}} = liftFree \ prod -> getRandEff (project elem prod)

suspend : {{Elem Suspend fs}} -> Nat -> Free (ProductN fs) Unit
suspend {{elem}} n = liftFree \ prod -> suspendEff (project elem prod) n

-------------------------------------------------------------------------------
-- Effect handlers
-------------------------------------------------------------------------------

handleExcep : HttpException -> Either Nat a
handleExcep _ = panic "unhandled HttpException"

httpIO : Http IO
httpIO .getHttpEff req = (right <$> get req) catch (pure <<< handleExcep)
httpIO .postHttpEff req body = (right <$> post req body) catch (pure <<< handleExcep)

logIO : Logging IO
logIO .logEff = putStrLn

randIO : Random IO
randIO .getRandEff = R.randomRIO (0 , 10)

suspendIO : Suspend IO
suspendIO .suspendEff = threadDelay

ioHandler : ProductN (Http :: Logging :: Random :: Suspend :: []) IO
ioHandler = cons httpIO $ cons logIO $ cons randIO $ cons suspendIO $ nil 

-------------------------------------------------------------------------------
-- Some programs
-------------------------------------------------------------------------------

repeatReq : {{Elem Http fs}} -> {{Elem Random fs}} -> {{Elem Suspend fs}}
  -> Url -> Free (ProductN fs) (Either Nat (Response Bytes))
repeatReq url = do
    numRetries <- getRand
    eResponse <- getHttp url
    go numRetries eResponse
  where
    go : Nat -> _ -> _
    go 0 r = pure r
    go (suc n) _ = do
        eResponse <- getHttp url
        case eResponse of \ where
            r@(right _) -> pure r
            l@(left _) -> suspend 100 >> go n eResponse

withLog : {{Elem Logging fs}}
  -> String -> String -> Free (ProductN fs) a -> Free (ProductN fs) a
withLog preMsg postMsg program = do
  logMsg preMsg
  a <- program
  logMsg postMsg
  pure a

program : {{Elem Http fs}} -> {{Elem Random fs}} -> {{Elem Suspend fs}} -> {{Elem Logging fs}}
  -> Free (ProductN fs) (Either Nat (Response Bytes))
program = withLog "running request!" "done!" (repeatReq "http://aaronlevin.ca")

-------------------------------------------------------------------------------
-- Interpreting the program
-------------------------------------------------------------------------------

main : IO Unit
main = interpret ioHandler program >> putStrLn "exit!"
