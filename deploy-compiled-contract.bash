#!/bin/bash
# $1 datadir of geth
# $2 account for deployment
# $3 password of account for deployment
# $4 bin file of contract

value=`cat $4`
echo $value

geth --datadir=./datadir --nodiscover --rpc --rpcapi "db,personal,eth,net,web3,debug" --rpccorsdomain='*' --rpcaddr="localhost" --rpcport 8545 --unlock $1 --password $2  --jspath . --preload ./mine-only-when-transactions.js  console