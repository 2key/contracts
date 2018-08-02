#!/bin/bash
# run to generate ethereum with 100 accounts
# interactive
# https://medium.com/@chim/ethereum-how-to-setup-a-local-test-node-with-initial-ether-balance-using-geth-974511ce712
# modify geth according to [geth.md](./geth.md)
rm -rf $HOME/geth
geth --datadir=$HOME/geth/localdev init genesis.dev.json

for i in {1..2}
do
    echo "GENERATIONG KEY " $i " ON TESTNET"
    geth --datadir=$HOME/geth/localdev account import --password passwords.dev <(sed -n "$i"p key.prv)
done


geth --datadir=$HOME/geth/localdev --nodiscover --rpc --rpcapi "db,personal,eth,net,web3,debug" --rpccorsdomain='*' --rpcaddr="0.0.0.0" --rpcport 8545 --networkid=17 --ws --wsaddr="0.0.0.0" --wsport=8546 --wsorigins="*" --mine --minerthreads 1 --gasprice 0 --targetgaslimit 9000000 --unlock '0,1' --password passwords.dev

# geth --rinkeby --ws --wsaddr="0.0.0.0" --wsport=8546 --wsorigins="*" --datadir=$HOME/.rinkeby --cache 2048 --rpc --rpcapi="db,personal,eth,net,web3,debug" --rpcaddr="0.0.0.0" --rpcport=8545 --syncmode fast --rpccorsdomain="*"