# SOLDeployer

```
brew install node@10
echo 'export PATH="/usr/local/opt/node@10/bin:$PATH"' >> ~/.bash_profile
export LDFLAGS="-L/usr/local/opt/node@10/lib"
export CPPFLAGS="-I/usr/local/opt/node@10/include"

```
bash redeploy-test.bash or ./redeploy-test-devonly.bash
yarn run deploy --migrate dev-local,private.test.k8s-hdwallet --reset

```
```
yarn run deploy public.test.k8s,private.test.k8s-hdwallet --reset
```
### How to deploy contracts to any network except local dev

* Commit your changes
* Pull changes from remote
* Make sure that all tests pass (```yarn run test```)
* Notice that after successful build 2key-protocol version you should run ```yarn run deploy --migrate dev-local``` to overwrite contracts meta 
* Change truffle.js and add your configuration (make sure that your network configs have correct rpcUrl and networkIds, also networkId required for ledger provider)
* Edit ContractDeploymentWhiteList.json
* Make sure that you on same branches in contracts and 2key-protocol submodule (./2key-protocol/dist)
* run ```yarn run deploy {comaseparated,networks} {truffle params if needed}```
* if you want to avoid deploying mock TwoKeyAcquisitionCampaignERC20 set ```SKIP_3MIGRATION=true```
* truffle migrate --f 3 --network=public.test.k8s-hdwallet in order to make new campaign eligible to emit events
* wait until process finish
* check both repos contracts and 2key-protocol should have same tags
* notify to #dev channel with builded tag. (update dependency in `web-app/package.json:twokey-protocol`)
```
### How to deploy contracts to local dev net without building release

* ```yarn run deploy --migrate {comaseparated,networks} {truffle params if needed}```
* enjoy

### Updating Whitelist of contracts

* edit `ContractDeploymentWhiteList.json`

### SOLDeployer commands

* ```--migrate``` - runs truffle migrate --network with generating ```contracts.ts``` abi interface and without running tests
* ```--test``` - runs tests from ```2key-protocol/test/index.spec.ts```
* ```--generate``` - runs generating ```contracts.ts``` abi interface from existing artifacts in ```build/contracts```
* ```--archive``` - archive current ```build/contracts``` to ```2key-protocol/src/contracts.tar.gz```
* ```--extract``` - extract from ```2key-protocol/src/contracts.tar.gz``` to ```build/contracts```
* ```--ledger``` - command for test LedgerProvider
* running without one of specified above flags will run default full deployment process with tests deployment archiving etc
