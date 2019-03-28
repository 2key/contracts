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
yarn run deploy --migrate dev-local,plasma-azure --reset
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

