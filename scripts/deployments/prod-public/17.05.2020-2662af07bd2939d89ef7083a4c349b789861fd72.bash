#!/usr/bin/env bash

spinner() {
    chars="/-\|"

    for (( j=0; j< $1; j++ )); do
      for (( i=0; i<${#chars}; i++ )); do
        sleep 0.5
        echo -en "${chars:$i:1}" "\r"
      done
    done
}

spinner 2


echo "Patch for Kyber withdraw tokens"

cd ../..
echo "Destination for execution of Admin patch bytecode: 0x60ece4a5be3fd7594e9f24c2948cce5ce3c6dde7"
python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.6

echo "Destination for execution is TwoKeyAdmin address : 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"
python3 generate_bytecode.py withdrawTokensFromReserve 0x00Cd2388C86C960A646D640bE44FC8F83b78cEC9 0xe48972fcd82a274411c01834e2f031d4377fa2c0 10000000000000000000 0x31cf9c7847c979313fe27eadfcc847a8a0252d86





