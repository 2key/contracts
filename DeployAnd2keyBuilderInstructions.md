# 2keyBuilder


# Deployment instructions

### How to test contracts
1. Make sure you have docker instance on your machine
    -   run `yarn` to install all dependencies
    - To run geth in docker please follow next steps:
      * [Install Docker](https://www.docker.com/get-started)
      * ```yarn run geth``` - to run build & run docker container
      * ```yarn run geth:stop``` - to stop docker container
      * ```yarn run geth:reset``` - to reset geth data folder (be carefull it will destroy all private node data)
      * Please notice that mining take a lot of hardware recources
      * Default exposed ports 8585 - rpc, 8546 - websockets
      * geth runs with 12 addresses if you need more please change ./geth/docker/genesis.2key.json ./geth/docker/key.prv ./geth/docker/passwords and ./geth/docker/geth.bash
      * First time run takes some time to generate all neccessary data
      

2. Go to the root of the project and run following command in terminal: `yarn run geth:start`
3. After that, you should see in terminal that blocks are being mined (1 minute approximately waiting time until that)
4. Make sure you have file named accountsConfig.json inside configurationFiles folder.
5. The file configurationFiles/accountsConfig.json should be in the following format:
```
{
  "address" : "",
  "mnemonic" : "",
  "mnemonic_private" : ""
}
```
6. This file should be filled with the address you want to use for tests, and the corresponding mnemonic
7. Once you have this file, you should run: `yarn run test:one 2key-protocol/test/sendETH.spec.ts` to get some test ether on local network
8. After this step you are ready to deploy contracts locally and run all the test over them
9. `yarn run deploy --migrate dev-local,plasma-test-local --reset`
10. `./test-funnel.sh` will run all the necessary tests

### External dependency
- Make sure to install all external dependencies
1. `curl https://raw.githubusercontent.com/Tenderly/tenderly-cli/master/scripts/install-macos.sh | sudo sh`

### How to do hard reset of network 
1. Make sure you have did all the steps related to the first title ("How to test contracts")
2. Make sure your configurationFiles/accountsConfig.json file contains address with enough ether for deploy
    - in case you're deploying with Ledger wallet, this file must be present but will be ignored
3. Make sure all 3 branches are up-to-date.
    - root
    - 2key-protocol/src
    - 2key-protocol/dist
4. Make sure you have .env-slack file. For content for this file ask @Nikola (necessary because deployment sends slack alerts)
5. Run the command `yarn run deploy network1,network2,...,networkN --reset`


### How to upgrade system with either 2key-protocol update or contracts patch
1. Make sure you have did all the steps related to the first title ("How to test contracts")
2. Make sure your configurationFiles/accountsConfig.json file contains address with enough ether for deploy
3. Update 2 cases:
    - Patch of protocol only `yarn run deploy update`
    - Patch of smart contracts (with or without protocol changes) `yarn run deploy <network> update` where network is the network to which contracts are deployed and you want to patch them


### Updating Whitelist of contracts during development

* edit `ContractDeploymentWhiteList.json`

### 2keyBuilder commands

* ```--migrate``` - runs truffle migrate --network with generating ```contracts.ts``` abi interface and without running tests
* ```--test``` - runs tests from ```2key-protocol/test/index.spec.ts```
* ```--generate``` - runs generating ```contracts.ts``` abi interface from existing artifacts in ```build/contracts```
* ```--archive``` - archive current ```build/contracts``` to ```2key-protocol/src/contracts.tar.gz```
* ```--extract``` - extract from ```2key-protocol/src/contracts.tar.gz``` to ```build/contracts```

### Deployment procedure

1. check tenderly 
``` tenderly whoami ```

2. make sure we're on required branches and pull everything:
```
cd 2key-protocol/src -> git pull & git reset HEAD --hard
cd 2key-protocol/dist -> git pull & git reset HEAD --hard
Same in root git pull & git reset HEAD --hard
```

3. run the migrations:
``` yarn run deploy private.staging-ledger,public.staging-ledger --reset ```

4. if pushing npm failed, you will need to continue the following manually:
```
cd 2key-protocol/dist
npm publish --tag staging (if you're on staging) OR npm publish --tag prod (if you're on prod)
cd ...  (back to root)
tenderly push --tag 1.2.0-staging   (or whatever git tag was created during the deploy)
```

5. push everything
```
cd 2key-protocol/src -> git add .
                        git commit -m 'sync-submodules'
                        git push -u
cd 2key-protocol/dist -> git add .
                         git commit -m 'sync-submodules'
                         git push -u
Same in root  -> git add .
                 git commit -m 'sync-submodules'
                 git push -u
```

6. in case tenderly push didn't succeed:
```
rm -rf build
yarn run deploy --extract
tenderly push --tag 1.2.0-staging
```

