# 2keyBuilder


# Deployment instructions

### How to test contracts
1. Make sure you have docker instance on your machine
    -   run `yarn` to install all dependencies
    -   [Install Docker](https://www.docker.com/get-started)
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

### Dependency
1. `curl https://raw.githubusercontent.com/Tenderly/tenderly-cli/master/scripts/install-macos.sh | sudo sh`

### How to do hard reset of network 
1. Make sure you have did all the steps related to the first title ("How to test contracts")
2. Make sure your configurationFiles/accountsConfig.json file contains address with enough ether for deploy
3. Run the command `yarn run deploy network1,network2,...,networkN --reset`


### How to upgrade system with either 2key-protocol update or contracts patch
1. Make sure you have did all the steps related to the first title ("How to test contracts")
2. Make sure your configurationFiles/accountsConfig.json file contains address with enough ether for deploy
3. Update 2 cases:
    - Patch of protocol only `yarn run deploy update`
    - Patch of smart contracts (with or without protocol changes) `yarn run deploy <network> update` where network is the network to which contracts are deployed and you want to patch them


### Updating Whitelist of contracts

* edit `ContractDeploymentWhiteList.json`

### 2keyBuilder commands

* ```--migrate``` - runs truffle migrate --network with generating ```contracts.ts``` abi interface and without running tests
* ```--test``` - runs tests from ```2key-protocol/test/index.spec.ts```
* ```--generate``` - runs generating ```contracts.ts``` abi interface from existing artifacts in ```build/contracts```
* ```--archive``` - archive current ```build/contracts``` to ```2key-protocol/src/contracts.tar.gz```
* ```--extract``` - extract from ```2key-protocol/src/contracts.tar.gz``` to ```build/contracts```

