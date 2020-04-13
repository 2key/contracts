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

echo "send 2KEY for testing distribution campaigns to admin account"
echo "TwoKeyAdmin contract proxy address on production: 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"
cd ../..

python3 generate_bytecode.py transfer2KeyTokens 0xD19b86369f0da8692774773E84D5A01394C02cF7 60000000

