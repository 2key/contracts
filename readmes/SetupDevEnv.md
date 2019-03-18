##### Setup development env

Every call assume you're in the root of the project

Before all: 
```angular2html
npm install
```

Make sure you have local geth running.
```angular2html
docker ps
```
There should be found `2key/geth:mainnet` under IMAGE. If not, you should run it: 

```angular2html
yarn run geth:reset
```
Create file named `accountsConfig.json` and fill it with following:
```angular2html
{
  "address" : "<SOME_ADDRESS>",
  "mnemonic" : "<MNEMONIC_FOR_THAT_ADDRESS>",
  "mnemonic_private" : "<EMPTY_FOR_NOW>",
  "infuraApiKey" : "<EMPTY_FOR_NOW>"
}
```
Make sure you have deployed contracts to local geth.

Bear in mind every time you reset geth you should deploy contracts again. 

Reset flag has the same functionality as in truffle -> override previous deployment
```angular2html
yarn run deploy --migrate dev-local,plasma-azure --reset
```

When deployment is finished, all addresses for the contracts will be under 2key-protocol/src/contracts_deployed-{branchName}.json
After contracts are deployed, in order to run complete test funnel you should send some 2key tokens to address we use as contractor


Make sure all the addresses on your geth have some ETH with following command
```angular2html
yarn run test:one 2key-protocol/test/sendETH.spec.ts
```



It will simulate voting in the congress to send 2key tokens from TwoKeyAdmin contract and execute voting.
```angular2html
yarn run test:one 2key-protocol/test/congressVote.spec.ts
```

After this is completed, big test (which covers the whole funnel) can be run : 
```angular2html
yarn run test
```





