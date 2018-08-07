#!/bin/bash
# use only after geth-init.bash
# geth will interactively request passwords for unlocking the first 2 accounts
geth --datadir=./datadir --nodiscover --rpc --rpcapi "db,personal,eth,net,web3,debug" --rpccorsdomain='*' --rpcaddr="localhost" --rpcport 8545 --ws --wsport=8546 --wsorigin="*" --networkid=17 --unlock '0,1'
ipfs daemon 2>&1 1>/dev/null &
# truffle migrate
# npm run generate &> /dev/null
# npm run dev 2>&1 1>/dev/null &
