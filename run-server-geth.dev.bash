#!/bin/bash
# use only after geth-init.bash
# modify geth according to [geth.md](./geth.md)
geth --datadir=./datadir/localdev --nodiscover --rpc --rpcapi "db,personal,eth,net,web3,debug" --rpccorsdomain='*' --rpcaddr="localhost" --rpcport 8545 --networkid=17 --ws --wsport=8546 --wsorigins="*" --mine --minerthreads 1 --gasprice 0 --targetgaslimit 9000000 --unlock '0,1' --password passwords.dev

#--enable-pubsub-experiment
#ipfs daemon &> log/ipfs.log &
