#!/bin/bash
# run to generate ethereum with 100 accounts
# interactive
# https://medium.com/@chim/ethereum-how-to-setup-a-local-test-node-with-initial-ether-balance-using-geth-974511ce712
# modify geth according to [geth.md](./geth.md)
rm -rf datadir
geth --datadir=./datadir/localdev init genesis.dev.json

for i in {1..2}
do
    echo "GENERATIONG KEY " $i " ON TESTNET"
    geth --datadir=./datadir/localdev account import --password passwords.dev <(sed -n "$i"p key.prv)
done
