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


echo "Destination for execution on plasma is TwoKeyPlasmaRegistry contract: 0x52f15890accdf9dac9b98f5afb177d83a4211e08"

cd ../..

python3 generate_bytecode.py setModeratorFeePlasma 10





