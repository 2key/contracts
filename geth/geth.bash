#!/bin/bash

if [ ! -d /tmp/geth.local ]; then
  mkdir -p /tmp/geth.local
fi

./stop.geth.bash
docker build -t 2key/geth:dev . 
docker run -p8545:8545 -p8546:8546 -v /tmp/geth.local:/root/.ethereum 2key/geth:dev --nodiscover --rpc --rpcapi "db,personal,eth,net,web3,debug" --rpccorsdomain='*' --rpcaddr="0.0.0.0" --rpcport 8545 --networkid=17 --ws --wsaddr="0.0.0.0" --wsport=8546 --wsorigins="*" --mine --miner.threads 1 --gasprice 0 --targetgaslimit 9000000 --unlock '0,1,2' --password /root/passwords