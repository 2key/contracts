##### Setup development env

Every call assume you're in the root of the project.
Use node version `10.9.0` for example:
```angular2
nvm use 10.9.0
```

Before all: 
```angular2html
npm install || yarn 
```

Make sure you have local geth running.
```angular2html
docker ps
```
There should be found `2key/geth:mainnet` under IMAGE. If not, you should run it: 
To run geth in docker please follow next steps:


* [Install Docker](https://www.docker.com/get-started)
* ```yarn run geth``` - to run build & run docker container
* ```yarn run geth:stop``` - to stop docker container
* ```yarn run geth:reset``` - to reset geth data folder (be carefull it will destroy all private node data)
* Please notice that mining take a lot of hardware recources
* Default exposed ports 8585 - rpc, 8546 - websockets
* geth runs with 12 addresses if you need more please change ./geth/docker/genesis.2key.json ./geth/docker/key.prv ./geth/docker/passwords and ./geth/docker/geth.bash
* First time run takes some time to generate all neccessary data


Create file named `accountsConfig.json` in the ./configurationFiles directory and fill it with following:
```angular2html
{
  "address" : "0xb3fa520368f2df7bed4df5185101f303f6c7decc",
  "mnemonic" : "laundry version question endless august scatter desert crew memory toy attract cruel",
  "mnemonic_private" : "<EMPTY_FOR_NOW>",
  "infuraApiKey" : "<EMPTY_FOR_NOW>"
}
```

Of course, this address will never have a real ether on mainnet, it's just user as testing address, that's why we expose it.

Make sure you have deployed contracts to local geth.
Bear in mind every time you reset geth you should deploy contracts again. 
Reset flag has the same functionality as in truffle -> override previous deployment.
You can deply using:
```angular2html
yarn run deploy --migrate dev-local,plasma-test-local --reset
```

When deployment is finished, all addresses for the contracts will be under 2key-protocol/src/contracts_deployed-{branchName}.json
After contracts are deployed, in order to run complete test funnel you should send some 2key tokens to address we use as contractor

To run tests you can run: `./test-funnel.bash`



