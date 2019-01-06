#### @2key/2key-protocol npm package

In order to test app locally you will need running docker container
- Simpliest way to run it is by executing command:
    - Make sure before running this that you have installed all dependencies
        - (npm install || yarn && yarn install)
```
yarn run geth
```

##### In order to update npm package run the following: 
- If there are no changes in singletones & plasma run following:
```
yarn run deploy --migrate dev-local,private.test.k8s
yarn run test:one 2key-protocol/test/sendETH.spec.ts
yarn run test:one 2key-protocol/test/updateTwoKeyReg.dev.spec.ts
yarn run test
git add .
git commit -m <"Commit message">
yarn run deploy public.test.k8s,private.test.k8s
```
- If there are changes in singletones and plasma (hard reset):
```
bash ./redeploy-test.bash
git add .
git commit -m <"Commit message">
yarn run deploy public.test.k8s,private.test.k8s --reset
```

- If the npm publish fails:
```
cd 2key-protocol/dist
npm publish
git push
```

- After this process is done make sure both (if not then push changes):
    - contracts repo (root) is up to date with branch
    - cd 2key-protocol/dist is up to date with branch
    



#### 2key-protocol submodule
That error means that projectfolder is already staged ("already exists in the index"). To find out what's going on here, try to list everything in the index under that folder with:

```git ls-files --stage projectfolder```
The first column of that output will tell you what type of object is in the index at projectfolder. (These look like Unix filemodes, but have special meanings in git.)

I suspect that you will see something like:

```160000 d00cf29f23627fc54eb992dde6a79112677cd86c 0   projectfolder```
(i.e. a line beginning with 160000), in which case the repository in projectfolder has already been added as a "gitlink". If it doesn't appear in the output of git submodule, and you want to re-add it as a submodule, you can do:

```git rm --cached projectfolder```
... to unstage it, and then:

```git submodule add url_to_repo projectfolder```

#### Github Pages Site
Url : https://2key.github.io/contracts/

in order to run the docs site locally, run the following command (cwd = project folder):
```
cd documentation/website
yarn || npm install
yarn start || npm start
```

in order to update the documentation manually, run the following command (cwd = project folder):

```
solidity-docgen ./ ./contracts ./documentation
```

all docusaurus related files are under the docs subfolder.

__very important__ this site is a public, do not pass it to anyone outside of twokey.

CI/CD integration is not yet available.

## Install

on osx:
```bash
latest version 9.11.1 from https://nodejs.org/en/
```

### cleaning up
If things stop working for you then maybe npm got all mixed up:

```angular2html
rm -rf node_modules/
rm -rf build/
npm cache clean --force
```

### regular install
make sure your anti-virus software is turned off before running `npm install...`
```
npm install
npm install -g truffle
npm install -g ganache-cli
```

## Running

In one window run

```angular2html
ganache-cli -d
```
this will simulate the blockchain locally.
You can do this operation in any directory.

running a full node of ether takes a lof ot time to download. for dev, there's a dev chain that takes just a few hours
but here, we're just running a simulator that starts a new chain just for our use, named `ganache-cli`, and it only has 1 node.

deploy the contracts

```angular2html
truffle migrate --reset # need to be done every time after starting ganaches
```

### running local web App
```angular2html
npm run dev
```
node.js is the javascript engine from chrome changed to become a full language in which you can use javascript for backend as well.
npm is the package manager of node.

open browser at [http://localhost:8080](http://localhost:8080)


# Running demo on AWS
```angular2html
# login
# EC2
# Lunch
# select Ubuntu Server 16.04 LTS (HVM), SSD Volume Type - ami-da05a4a0
# select t2-large
# select secure policy to allow inbound TCP connection from anywhere on ports 8080,8545, 5001
# and press Review and Lunch
# select ssh key you have (e.g. 2k2.pem) click "I accept..."
# View Instance (bottom right)
# notice Public IP of your instance (e.g. ec2-18-218-88-210.us-east-2.compute.amazonaws.com)
# wait
ssh -a ~/amazon/keys/2k2.pem ubuntu@ec2-18-218-88-210.us-east-2.compute.amazonaws.com
# yes
# inside AWS EC2 instance
sudo apt-get update
sudo apt-get upgrade

git config --global credential.helper 'cache --timeout=3600'  # run this only once on the machine
git clone https://github.com/2keynet/web3-alpha.git
# enter user name/password for github
git checkout <branch>

curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g ganache-cli
# run ganache a blockchain simulator in the background
# -d run ganache determinsticly so we will have the same accounts each time
# -a 1000 generate 1K accounts
ganache-cli -d -a 1000 2>1 > /dev/null &

sudo npm install
sudo npm install -g truffle
# truffle compile  # not needed
truffle migrate --reset  # overwride the previous contract with same name
# run web server in the backgound
npm run dev  2>1 > /dev/null &
```
Now on your local machine open [http://localhost:8080](http://localhost:8080)

Or you can run firefox on the AWS EC2 instance itself.
First install X11 server on your local machine. Follow instructions at
https://www.xquartz.org/.
Next connect to the AWS EC2 instance with this ssh command
```
ssh -i udi1.pem -Y ubuntu@34.207.63.53
```
Now install and run firefox on the remote machine:
```
sudo apt install -y firefox
firefox http://localhost:8080
```

# IPS
## Install
https://ipfs.io/docs/install/
### OSX
```angularjs
wget https://dist.ipfs.io/go-ipfs/v0.4.13/go-ipfs_v0.4.13_darwin-amd64.tar.gz
tar xvfz go-ipfs_v0.4.13_darwin-amd64.tar.gz
cd go-ipfs
sudo ./install.sh
```
### AWS
```angularjs
sudo apt-get update
sudo apt-get install golang-go -y
wget https://dist.ipfs.io/go-ipfs/v0.4.13/go-ipfs_v0.4.13_linux-386.tar.gz
tar xvfz go-ipfs_v0.4.13_linux-386.tar.gz
sudo mv go-ipfs/ipfs /usr/local/bin/ipfs
```
Allow access to port `5001`

### Run
TODO the following has zero security
```angularjs
ipfs init
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin "[\"*\"]"
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials "[\"true\"]"
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config Addresses.Gateway /ip4/127.0.0.1/tcp/8082
ipfs daemon
```
make sure your in the project root
```angularjs
npm i ipfs-api
```

```
npm ls -gp --depth=0 | awk -F/ '/node_modules/ && !/\/npm$/ {print $NF}' | sudo xargs npm -g rm
sudo npm i -g ganache-cli@6.0.3
npm show truffle@* version
sudo npm i -g truffle@4.0.6
```


# Free Join Link example
### Limitations
* Only the path leading to conversrion will reach the contract and be KNOWN.
* Limit on 8 steps (can be solved with IPFS)
* Delayed update on contract and only on converstion: the first CONVERTER to convert is the first to take ARCs
all the way for all influencers.
The record of influencers is written into the contract only on the moment of conversion and not when the influencers
JOINED a link.
* Converter has to pay a small gas fee (about $0.25)

## link created by the owner of the contract
For example `coinbase` is the owner.
```
http://poc.2key.network:8080/?c=0x14979e992ba175db78ca3363c38d4d1a95588ecc&f=0xe1ab544ca8c217acbbc82199ff64b840ddfd6d86&s=a49ace02fedb0c441476ad7d8d1cdbeae507c64f43ae6d84dbc73bb6ae097828
```
* c - contract address
* f - who created this link - contractor
* s - NEW secret - available ONLY on this link. s is also a NEW private key


In addition the contractor writes in the contract (using method `setOwnerPublicLinkKey` the public key of **s**)
THIS REQUIRES AN OPEN WALLET AND GAS.


## Conversion from link received from contractor
* generate signature:
  * sign(hash(the address of the influencer + public key of **new s**), using **previous s** which is a private key)
* call `transferSig` method of contract (sub class of `TwoKeySignedContract`)
  * THIS REQUIRES AN OPEN WALLET AND GAS
  * the contract reads the signature:
    * check it is valid
  * Move all the ARCs for all the influencers along the path if they didnt had ARCs up to now.

## link created by influencer from link received from contractor
NO WALLET NO GAS
Influencer is `moshe3`

```
http://poc.2key.network:8080/?c=0x14979e992ba175db78ca3363c38d4d1a95588ecc&f=0x63a421dd47e1c1e3066ffee4b22c43b76e732837&s=e00a444be6b01277774c0043ee2640b4501ef0d0ca50c90185053d03f7c50a0f&m=689302cf91abe32becb674aaa2e37b012b8108e6fad139722e8cb2df3798c2975c31e5cbdd2051ec86889cf8a5353b83191c61476fe0a23c5f5a168859c0d3a61b
```
* c - contract address
* f - who created this link - current influencer
* s - NEW secret - available ONLY on this link. s is also a NEW private key
* m - message:
  * sign(hash(the address of the influencer + public key of **new s**), using **previous s** which is a private key)

## link created by influencer from upstream influencer
NO WALLET NO GAS
Influencer is `jack`

```
http://poc.2key.network:8080/?c=0x14979e992ba175db78ca3363c38d4d1a95588ecc&f=0x4ac2296246806db88c3e80d8129b7514fe9031ff&s=a9be43165d33305dccf87def1e7299c29b828fca7144fa2881c8597516f25cbf&m=689302cf91abe32becb674aaa2e37b012b8108e6fad139722e8cb2df3798c2975c31e5cbdd2051ec86889cf8a5353b83191c61476fe0a23c5f5a168859c0d3a61b63a421dd47e1c1e3066ffee4b22c43b76e7328379062055f56e0aa394874932b43b7ffa517df4bd89fc32452d6e100d8419a570936eccc8544ab41872effac73a4fa516c4459b7e402173ab5c025db8e1e9fcc1c92291ad88724ae04d1cb49c793b341b2c24708561b
```

* c - contract address
* f - who created this link - current influencer
* s - NEW secret - available ONLY on this link. s is also a NEW private key
* m - message:
  * all the previous m
  * public key of the previous secret **s** (of `moseh3`.
  I can not put public key of someone else because I dont know the secret of the previous s, `coinbase` and
  I need to have it because it was used to sign `moshe3` inside `m`)
  * address of the previous influencer
  * sign(hash(the address of the influencer + public key of **new s**), using **previous s** which is a private key)

## Conversion from link received from jack

THIS REQUIRES AN OPEN WALLET AND GAS.
Gas used 405K = $0.23 (ETH=$585)


# SSH
in file `/etc/ssh/sshd_config` set `PasswordAuthentication` to `yes`
```bash
ssh ubuntu@poc.2key.network
```
enter password

# Local Development Environment

Use Node.js v9.11.1 to be compatible with truffle that we used so far.

## Geth

Run in folder containing `contracts`.

Run with:

    geth --datadir=./datadir --nodiscover --rpc --rpcapi "db,personal,eth,net,web3,debug" --rpccorsdomain='*' --rpcaddr="localhost" --rpcport 8545 --unlock 0,1,2,3,4,5,6 --password password.geth.remix.txt  --jspath . --preload contracts/mine-only-when-transactions.js  console

Assuming we previously created 5 acounts. The password file should have a line with the password for each account to be unlocked.

## TESTNET Docker
To run geth in docker please follow next steps:
* [Install Docker](https://www.docker.com/get-started)
* ```npm run geth``` - to run build & run docker container
* ```npm run geth:stop``` - to stop docker container
* ```npm run geth:reset``` - to reset geth data folder (be carefull it will destroy all private node data)
* Please notice that mining take a lot of hardware recources
* Default exposed ports 8585 - rpc, 8546 - websockets
* geth runs with 12 addresses if you need more please change ./geth/docker/genesis.2key.json ./geth/docker/key.prv ./geth/docker/passwords and ./geth/docker/geth.bash
* First time run takes some time to generate all neccessary data
* All steps before valid only for unix based OS if you have Windows based ping Adnrii Pindiura for a help

## Remix

Browser-based IDE - works in Safari and Chrome on MacOSX

    http://remix.ethereum.org

Use the the `http`  to work with Geth.

In the **Run** tab, select Provider to be *Web3 Provider*.

## ABI and Bytecode

After compiling contract, click on **Details** to copy them manually

## Remixd

Connect Remix to local files.

[Remixd](https://github.com/ethereum/remixd)

    npm install -g remixd

Run with:

    remixd -s contracts

## Open Local Files in Remix

In Remix, in the top left corner, click the link icon to connect to Remixd.

In the left sidebar, all your files appear under `localhost`. Editing can be done either in IDE or in Remix. There is no `save` action in Remix, so files are updated immediately in the file system.

## Compiler

[Solidity Compiler (solc)][http://solidity.readthedocs.io/en/v0.4.24/installing-solidity.html]

### MacOSX

Install with `brew`

    brew update
    brew upgrade
    brew tap ethereum/ethereum
    brew install solidity

## Compiling Files

    ./compile-with-solc.bash

ABI and Bytecode will be generate in target folder `solcoutput`

## Deploying

Enter into geth console:

    var byteCode = "606060405234...";
    // You get the byte code from the bin file in solcoutput
    personal.unlockAccount(eth.accounts[0], "yourpassword")
    eth.sendTransaction(
       {
         from: eth.accounts[0],
         data: "0x" + counterCode,
         gas: 1000000
       },
       function(err, tx) {
         console.log(err, tx);
       }
    );

# SOLDeployer

How to deploy contracts to any network except local dev

* Change truffle.js and add your configuration
* Edit ContractDeploymentWhiteList.json
* Commit your changes
* Make sure that you on same branches in contracts and 2key-protocol submodule (./2key-protocol/dist)
* run ```yarn run deploy {network} {truffle params if needed}```
* wait until process finish
* check both repos contracts and 2key-protocol should have same tags



# Docker testnet

You need docker installed on your machine [See here](https://www.docker.com)

```
npm run geth:stop
rm -rf ./build/geth.dev
npm run geth
```


Chaindata stored in ```./build/geth.dev``` you can remove it if need clean
To run docker
```npm run geth```
you can close console if needed docker will continue work
To stop docker
```npm run geth:stop```
