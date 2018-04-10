#!/bin/bash
ganache-cli -a 100 > log &
ipfs daemon 2>&1 1>/dev/null &
truffle migrate
npm run dev 2>&1 1>/dev/null &

