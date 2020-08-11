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
echo "Destination for execution is TwoKeyPlasmaRegistry contract: 0x7bcd4b4e1594882106d384f9ee87725a2be1ca20"
cd ../..

python3 generate_bytecode.py setModeratorFeePlasma 5






