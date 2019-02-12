# GETH private development node

### Pre requirements

* Docker (link)[https://www.docker.com]
* NodeJS (link)[https://nodejs.org/en/]


## Important!
* before run `geth` or `plasma` please copy passwords.txt to ```./geth/mainnet/``` and ```./geth/plasma/``` 


### GETH
* chainId - `8086`
* ```yarn run geth``` - will look for currently running geth docker and restart it or start new container
* ```yarn run geth:stop``` - stop running container
* ```yarn run geth:reset``` - clear geth volume `gethmainnet` and start container

### PLASMA
* chainId - `8087`
* ```yarn run plasma``` - will look for currently running geth docker and restart it or start new container
* ```yarn run plasma:stop``` - stop running container
* ```yarn run plasma:reset``` - clear geth volume `gethplasma` and start container

### Other
* params to start docker you can find in ```geth/{net}/geth.{net}.js```
* list of fullfiled account and genesis block you can find in ```geth/{net}/genesis.json``` (please avoid to commit changes in this folder)
* v3 keys stored in ```geth/{net}/keys``` for passwords ask `Andrii Pindiura`
