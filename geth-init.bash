#!/bin/bash
# run to generate ethereum with 2 accounts
# interactive
geth --datadir=./datadir init genesis.json
geth --datadir=./datadir --networkid=17 account new
geth --datadir=./datadir --networkid=17 account new