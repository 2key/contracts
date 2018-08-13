#!/bin/bash

solc --bin --abi -o ./solcoutput github.com/OpenZeppelin/openzeppelin-solidity/contracts=$PWD/node_modules/openzeppelin-solidity/contracts  ./contracts/*.sol
