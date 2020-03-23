# 2key-protocol Developer guid

### How to prepare environment

* ```yarn run geth``` - to start local devnet
* deploy contracts with ```yarn run deploy --migrate dev-local,plasma-test-local --reset``` this will deploy new contracts to your local node and remote syncEventsNode (http://astring.aydnep.com.ua:18545)
* setup ```.env``` file and specify mnemonics and addresses of accounts
* run ```yarn run test:all``` to start all tests

* after all steps passed you can continue with development

How to run specific part of the tests:
* run ```yarn run test:examples``` to start example tests, these tests include almost all available user actions 
* run ```yarn run test:cpc``` to start cpc tests
* run ```yarn run test:acquisition``` to start acquisition tests
* run ```yarn run test:mvp``` to start mvp tests, includes acquisition and donation tests
* run ```yarn run test:donation``` to start donation tests, for now we have only two donation variations and they includes to mvp

### How run Metamask debugger app

* ```yarn start```

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
|    |    |----index.ts - Udi math|crypto stuff for offchain joining
|    |----contracts.json - abi of whitelisted contracts generated with 2keyBuilder (currently unused)
|    |----contracts.tar.gz - backup of deployed contracts to staging (ropsten.infura)
|    |----contracts.ts - our solidity abi interface that also contains bytecodes and networks address of all our
|    |                   singletone and other contracts that used in our 2key-protocol class
|    |----index.ts - our 2key-protocol entrypoint
|    |----interfaces.ts - definitions of all functions and datastructures
|----dist - submodule that synced with github.com/2key/2key-protocol repo here webpack will build our library
|----test - tests folder
|    |----campaignsTests - all related tests to campaigns includes
|           |----reusable - reusable campaign checks and user actions
|           |----variations - directory with described cmapaigns variations
|    |----constants - all constants related to tests
|    |----examples - example with almost all available user actions for specific campaign, don't run with all other tests
|    |----helperClasses - classes which used for organise information for further compare with test results
|    |----helpers - helper functions
|    |----oldTestsBackup - tests from previous version, should be removed in future  
|    |----typings - some typescript types 
|    |----unitTests - isolated contracts tests also includes required tests which affect environment prepare
|    |----index.html - debugger app with metamask support\
|    |----webapp.ts - script for debugger app
```
