Read google doc "2key-zkSNARKs mode" for details on how it works
# How to use ZoKrate
* follow [these instructions](https://github.com/jstoxrocky/zksnarks_example) once:
```angularjs
# Clone the repo
git clone https://github.com/JacobEberhardt/ZoKrates.git
cd ZoKrates
# Build the Docker image
docker build -t zokrates .
```
* Run a zokrates container and jump inside
```
# can be run from any directory
docker run -ti zokrates /bin/bash
cd ZoKrates
```
* copy paste `verify.code` to the docker `x`
* compile
```angularjs
./target/release/zokrates compile -i x
./target/release/zokrates setup
./target/release/zokrates export-verifier
```
* check the code is running by running ONE of the following
```angularjs
hash.py 1 0 1
hash.py 3 98798797979676567588 298896887978787546
```
and follow instructions on how to run `zokrates compute-witness` you should get `1` as final answer
* copy paste back the generated contract `verifier.sol` to `./contracts`
* copy paste back paramaters for Dapp
The Dapp should do something similar to
* read maximal depth from contract
* compute N from URL = maximal_depth - # of ipfs addresses in link
* read h from URL
* remove h from link add hash(h) to link
* compute H = hash**N(h)
* read the influencer address I
* compute HI = hash(h+I)
* compute a proof similar to the following rust command line
```angularjs
# parameters below are H=5, N=1, HI=5, I=0
./target/release/zokrates compute-witness -a 5 1 5 0
# when asked to enter 'h', enter:
1
./target/release/zokrates generate-proof
```
* save 8 paramaters in ipfs file
* add address to ipfs file to link
* when buying the Dapp should read all ipfs address from link
* send h and the content of all ipfs files in order to contract buy method
