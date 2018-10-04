# GETH private development node

### Pre requirements

* Docker (link)[https://www.docker.com]
* NodeJS (link)[https://nodejs.org/en/]


### Run geth node

* ```yarn run geth``` - will look for currently running geth docker and restart it or start new container
* ```yarn run geth:stop``` - stop running container
* ```yarn run geth:reset``` - clear geth datadir ```build/geth.dev``` and start container

### Other

* datadir - ```build/geth.dev```
* chainId - 8086
* params to start docker you can find in ```geth/geth.js```
* list of fullfiled account and genesis block you can find in ```geth/docker/genesis.2key.json``` (please avoid to commit changes in this folder)
* private keys stored in ```geth/docker/key.prv```
