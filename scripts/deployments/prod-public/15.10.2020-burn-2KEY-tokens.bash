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

echo "Burn 2KEY tokens on either TwoKeyEconomy contract or https://etherscan.io/address/0x0000000000000000000000000000000000000001"
echo "TwoKeyAdmin contract proxy address on production: 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"
cd ../..

python3 generate_bytecode.py transfer2KeyTokens <DESTINATION ADDRESS> <AMOUNT_OF_TOKENS_REGULAR_NUMBER_NOT_WEI>

