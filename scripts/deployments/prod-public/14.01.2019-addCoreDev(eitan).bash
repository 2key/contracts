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

echo "Add this address: 0x6504AAD8Bdd40A73A54D65AfeaC146488Db2e31E as core dev to the system on mainnet"
echo "Destination for execution of this script is Proxy address of TwoKeyAdmin: 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"

cd ../..

python3 generate_bytecode.py addCoreDevs 0x6504AAD8Bdd40A73A54D65AfeaC146488Db2e31E
