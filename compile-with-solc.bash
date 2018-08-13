#!/bin/bash
# $1 parameter is absolute pathb to repo
solc --bin --abi -o ./solcoutput github.com/OpenZeppelin/openzeppelin-solidity/contracts=$PWD/node_modules/openzeppelin-solidity/contracts  ./contracts/*.sol
