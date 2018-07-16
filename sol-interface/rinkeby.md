In order to deploy contracts on [rinkeby](https://www.rinkeby.io) do the following:

* The address used to install the contracts is 0xb3fa520368f2df7bed4df5185101f303f6c7decc
* you can see its past activity and balance on [etherscan](https://rinkeby.etherscan.io/address/0xb3fa520368f2df7bed4df5185101f303f6c7decc)
* make sure the address has Ether balance on rinkeby
* go through each of the files in `migrations/` folder and make sure that only the contracts you want to be deployed are inside an `if(... deployer.network == "rinkeby-infura")` condition
* type:
```bash
truffle migrate --network rinkeby-infura --reset > rinkeby.log
```
* see whats happening on [etherscan](https://rinkeby.etherscan.io/address/0xb3fa520368f2df7bed4df5185101f303f6c7decc)

* finally add changes to this repo and tag it
```bash
git add -f build/contracts/*
git commit -am "deployed to rinkeby"
git tag -a rinkeby<date> -m "installed on rinkeby on <date> <time>"
git push origin rinkeby<date>
```

