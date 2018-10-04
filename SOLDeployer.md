# SOLDeployer

### How to deploy contracts to any network except local dev

* Make sure that all tests pass (```yarn run test```)
* Change truffle.js and add your configuration
* Edit ContractDeploymentWhiteList.json
* Commit your changes
* Make sure that you on same branches in contracts and 2key-protocol submodule (./2key-protocol/dist)
* run ```yarn run deploy {network} {truffle params if needed}```
* wait until process finish
* check both repos contracts and 2key-protocol should have same tags

### How to deploy contracts to local dev net without building release

* ```yarn run deploy --migrate {network} {truffle params if needed}```
* enjoy

### SOLDeployer commands

* ```--migrate``` - runs truffle migrate --network with generating ```contracts.ts``` abi interface and without running tests
* ```--test``` - runs tests from ```2key-protocol/test/index.spec.ts```
* ```--generate``` - runs generating ```contracts.ts``` abi interface from existing artifacts in ```build/contracts```
* ```--archive``` - archive current ```build/contracts``` to ```2key-protocol/src/contracts.tar.gz```
* ```--extract``` - extract from ```2key-protocol/src/contracts.tar.gz``` to ```build/contracts```
* ```--ledger``` - command for test LedgerProvider
* running without one of specified above flags will run default full deployment process with tests deployment archiving etc
