# WIP: Agda base library

This is an attempt at creating a base library for Agda. Unlike the agda-stdlib
library, which is designed with proving in mind (and requires emacs configured
with the Agda input method in order to type all those fancy unicode symbols),
this library is meant to be a general purpose "batteries-included" base library
that doesn't require emacs to use and is keyboard friendly.

The design is mostly based on GHC's base library, but a lot of ideas were
"stolen" from libraries and packages from hackage, pursuit, agda-stdlib,
agda-prelude, Idris and other sources.

## How to install with `brew` (macOS Mojave)

```sh
# Install agda
brew install agda

# Clone the project somewhere (or download the code and unzip it somewhere)
git clone https://github.com/berndlosert/agda-base.git

# Set up the base library
mkdir ~/.agda
echo <path to base library>/base-library.agda-lib >> ~/.agda/libraries
echo base-library >> ~/.agda/defaults

# Needed to compile agda programs into executables
cabal update
cabal install --lib ieee754
cabal install --lib network # Needed by Network.Socket code
```

N.B. `brew install agda` will install a couple of "unnecessary" things:
* the agda-stdlib (under /usr/local/lib/agda)
* emacs

To uninstall emacs, do the following:

```sh
# Uninstall emacs
brew uninstall --ignore-dependencies emacs

# Uninstall emacs dependencies (brew really needs an option for this)
brew deps emacs | xargs -n 1 brew uninstall --ignore-dependencies

# Uninstall leftover files
rm -rf /usr/local/etc/unbound
rm -rf /usr/local/etc/gnutls
rm -rf /usr/local/etc/openssl@1.1
rm -rf /usr/local/etc/ca-certificates
rm -rf /usr/local/share/emacs/site-lisp/agda
```

## Hello world!

Save the following code into a file called `hello.agda`.

```agda
open import Prelude
open import System.IO

main : IO Unit
main = print "Hello world!"
```

Compile it like so:

```
agda --compile hello.agda
```

## A more complex example

Save the following code into a file called `echo-server.agda`:

```agda
{-# OPTIONS --guardedness #-}

open import Prelude

open import Data.Bytes as Bytes using ()
open import Data.List as List using ()
open import Data.String.Encoding
open import Network.Socket
open import System.IO

runTCPEchoServer : IO Unit
runTCPEchoServer = do
  (serverAddr , _) <- getAddrInfo nothing (just "127.0.0.1") (just "7000")
  serverSocket <- socket (addrFamily serverAddr) sockStream defaultProtocol
  setSocketOption serverSocket reuseAddr 1
  bind serverSocket (addrAddress serverAddr)
  listen serverSocket 1
  (clientSocket , _) <- accept serverSocket
  print "Waiting for a message..."
  message <- recv clientSocket 1024
  unless (Bytes.null message) do
    print ("Received: " <> decodeUtf8 message)
    print "Echoing..."
    sendAll clientSocket message
  print "Closing..."
  close clientSocket
  close serverSocket

main : IO Unit
main = runTCPEchoServer
```

Compile this code by running `agda --compile echo-server.agda`. If you get the
following errors:

```
Compilation error:

MAlonzo/Code/Network/Socket.hs:17:1: error:
    Could not find module ‘Network.Socket.ByteString’
    Use -v (or `:set -v` in ghci) to see a list of the files searched for.
   |
17 | import Network.Socket.ByteString
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

MAlonzo/Code/Network/Socket.hs:18:1: error:
    Could not find module ‘Network.Socket’
    Use -v (or `:set -v` in ghci) to see a list of the files searched for.
   |
18 | import Network.Socket
   | ^^^^^^^^^^^^^^^^^^^^^
```

then you need to make sure you have the `network` package installed. Run `cabal
install --lib network` to install it and try compiling again. Once it compiles,
start the program by running `./echo-server`. In a different terminal
tab/window, run `telnet localhost 7000` and type in `Hello World!`. The
`echo-server` will echo what you just typed and exit.
