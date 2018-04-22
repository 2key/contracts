#!/bin/bash
# we dont want to be deterministic so dont use -d or -s or -m
# this will make sure browsers running older versions will not interact
# start with 100 accounts
ganache-cli -d -a 100 2>&1 1>log &
ipfs daemon 2>&1 1>/dev/null &
truffle migrate
npm run dev 2>&1 1>/dev/null &
