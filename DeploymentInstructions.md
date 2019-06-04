### Deployment instructions

This is readme file to describe necessary actions in order to redeploy
2key-protocol npm package.

To disallow deploying not working code, in order to deploy our tests must pass.


In order to deploy contracts make sure you have in the root directory 
file named `accountsConfig.json`. If not, create one with the following:
```
{
  "address" : <your deployer address> //feature-> NOT NECESARRY
  "mnemonic" : <MNEMONIC> 
  "mnemonic_private" : NOT NECESARRY FOR NOW
  "infuraApiKey" : <INFURA_API_KEY>
}
```

If you're deploying with Ledger, the config file will be just used for the testing on dev-local and plasma deployment.

After this is done, run this sequence of commands:
```
yarn run geth:reset (Will run docker instance)
yarn run test:one 2key-protocol/test/sendEth.spec.ts
yarn run deploy --migrate dev-local,plasma-test-local --reset
yarn run test:one 2key-protocol/test/congressVote.spec.ts
yarn run test
```

After all tests pass you'll have to run one of deploy commands depending of
deployment type and network deploying to.

Network names can be found in truffle.js file inside root of the repository.
The ones we use most often are:
* `public.test.k8s-hdwallet` - deploying to ropsten network with hdwallet
* `public.test.k8s` - deploying to ropsten network with ledger
* `plasma-azure` - Plasma azure network
* `dev-local` - Docker container used as development environment


##### Soft redeploy
If there have been only changes in 2key-protocol, or in the non-singleton contracts,
will be enough to run soft redeploy.

1. Changes made only on one network (plasma || mainnet)
```
yarn run deploy <network>
```
2. There are changes in both networks (plasma && mainnet)
```
yarn run deploy <network1>,<network2>
```

##### Hard redeploy
If there have been changes in core singleton contracts, we should hard redeploy everything
which means all the storage will be lost and will require db wipe on the backend side.

```
yarn run deploy <network1>,<network2> --reset
```



For both redeploy types: 
This commands will run a couple of scripts, and at the end they'll run 3rd migration
in order to make sure code of our campaigns will be validated by our campaign validator.
After all that stuff is done, it will generate submodules, create package and try to
publish npm package and push tags to the github repos:

1. https://github.com/2key/2key-protocol
2. https://github.com/2key/contracts



### 2key.network contracts repository

This repository will be used as 

#### @2key/2key-protocol npm package

In order to test app locally you will need running docker container
- Simpliest way to run it is by executing command:
    - Make sure before running this that you have installed all dependencies
        - (npm install || yarn && yarn install)
```
rm -rf build
yarn run geth:reset
```
#### Network configuration

- In order to deploy contracts make sure you have in the root directory 
file named `accountsConfig.json`. If not, create one with the following:
```
{
  "address" : <your deployer address> //feature-> NOT NECESARRY
  "mnemonic" : <MNEMONIC> 
  "mnemonic_private" : NOT NECESARRY FOR NOW
  "infuraApiKey" : <INFURA_API_KEY>
}

```


#### In order to update npm package run the following: 
- If there are no changes in singletones & plasma run following:
```
yarn run deploy --migrate dev-local,plasma-azure   (add --reset if this is hard reset)
yarn run test:one 2key-protocol/test/sendETH.spec.ts
yarn run test:one 2key-protocol/test/congressVote.spec.ts
yarn run test
git add .
git commit -m <"Commit message">
yarn run deploy public.test.k8s,plasma-azure  (add --reset if this is a hard reset)
```
- If there are changes in singletones and plasma (hard reset):
```
bash ./redeploy-test.bash
git add .
git commit -m <"Commit message">
yarn run deploy public.test.k8s,private.test.k8s --reset
```

- regular deploy
```
bash ./redeploy-test.bash
git add .
git commit -m <"Commit message">
yarn run deploy public.test.k8s,private.test.k8s-hdwallet
```

- deploying with only public network
```bash
yarn run deploy --migrate dev-local --reset
yarn run test:one 2key-protocol/test/sendETH.spec.ts
yarn run test:one 2key-protocol/test/updateTwoKeyReg.dev.spec.ts
yarn run test
git add .
git commit -m <"Commit message">
yarn run deploy public.test.k8s
```

- If the npm publish fails:
```
cd 2key-protocol/dist
npm publish (if develop/staging : npm public --tag branch_name)
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





## TESTNET Docker
To run geth in docker please follow next steps:
* [Install Docker](https://www.docker.com/get-started)
* ```yarn run geth``` - to run build & run docker container
* ```yarn run geth:stop``` - to stop docker container
* ```yarn run geth:reset``` - to reset geth data folder (be carefull it will destroy all private node data)
* Please notice that mining take a lot of hardware recources
* Default exposed ports 8585 - rpc, 8546 - websockets
* geth runs with 12 addresses if you need more please change ./geth/docker/genesis.2key.json ./geth/docker/key.prv ./geth/docker/passwords and ./geth/docker/geth.bash
* First time run takes some time to generate all neccessary data




# 2keyBuilder

How to deploy contracts to any network except local dev

* Change truffle.js and add your configuration
* Edit ContractDeploymentWhiteList.json
* Commit your changes
* Make sure that you on same branches in contracts and 2key-protocol submodule (./2key-protocol/dist)
* run ```yarn run deploy {network} {truffle params if needed}```
* wait until process finish
* check both repos contracts and 2key-protocol should have same tags

