#!/bin/bash
ganache-cli -d 2>&1 1>/dev/null &
ipfs daemon 2>&1 1>/dev/null &
truffle migrate
npm run dev

