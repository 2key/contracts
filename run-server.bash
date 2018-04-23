#!/bin/bash
# we dont want to be deterministic so dont use -d or -s or -m
# this will make sure browsers running older versions will not interact
# start with 100 accounts
ganache-cli -p 8877 -a 100 &> log &
ipfs daemon &> /dev/null &
truffle migrate &> /dev/null
npm run dev &> /dev/null &
