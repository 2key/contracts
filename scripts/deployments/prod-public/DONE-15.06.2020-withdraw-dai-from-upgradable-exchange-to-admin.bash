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


cd ../..


echo "Destination for execution of 1 time function calls: 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"

python3 generate_bytecode.py withdrawDAIFromUpgradableExchangeToAdmin 0




