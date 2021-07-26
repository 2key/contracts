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


echo "Set liquidity params through TwoKeyAdmin contract on Kyber network"

echo "Destination for execution is TwoKeyAdmin address : 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"

cd ../..

python3 generate_bytecode.py withdrawUpgradableExchangeDAICollectedFromAdminContract 0xd19b86369f0da8692774773e84d5a01394c02cf7 0

