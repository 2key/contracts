# 2key-protocol Developer guid

### How to prepare environment

* ```yarn run geth``` - to start local devnet
* deploy contracts with ```yarn run deploy --migrate dev-local,plasma-ap --reset``` this will deploy new contracts to your local node and remote syncEventsNode (http://astring.aydnep.com.ua:18545)
* setup ```.env``` file and specify mnemonics and addresses of accounts
* run ```yarn run test:one 2key-protocol/test/sendETH.spec.ts``` - this test will send ETH to all accounts used in test
* run ```yarn run test``` to start tests
* after all steps passed you can continue with development

### Folder structure

```
2key-protocol
|----README.md - this file
|----src - sources of 2key-protocol
|    |----acquisition - Acquisition Campaign functionality
|    |    |----index.ts - entrypoint that imported as AcquisitionCampaign subclass to our 2key-protocol class
|    |----utils - utils and helpers functions
|    |    |----helpers.ts - common private methods used in 2key-protocol class and all nested subclasses
|    |    |----index.ts - entrypoint that imported as Utils subclass to our 2key-protocol class
|    |    |----sign.ts - Udi math|crypto stuff for offchain joining
|    |----contracts.json - abi of whitelisted contracts generated with SOLDeployer (currently unused)
|    |----contracts.tar.gz - backup of deployed contracts to staging (ropsten.infura)
|    |----contracts.ts - our solidity abi interface that also contains bytecodes and networks address of all our
|    |                   singletone and other contracts that used in our 2key-protocol class
|    |----index.ts - our 2key-protocol entrypoint
|    |----interface.ts - definitions of all functions and datastructures
|----dist - submodule that synced with github.com/2key/2key-protocol repo here webpack will build our library
|----test - tests folder
|    |----_web3.ts - test helpers to create web3 instance with wallet provider
|    |----index.spec.ts - the main test scenario, in feature we need to split this to different cases
|    |----sendETH.spec.ts - test for fullfilling all needed accounts (look at .env file) with 10ETH
|    |----sendTokens.spec.ts - test for sending truffle2Key tokens to aydnep accounts in staging network
```
