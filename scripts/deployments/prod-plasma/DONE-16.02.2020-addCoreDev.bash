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

echo "Generating bytecode to add Nikolas address as a core dev on plasma"
echo "Destination for execution: 0xc13c57a5c488211b26c7fb63db091d78d5c3ae47"
cd ../..
python3 generate_bytecode.py addCoreDevsPlasma 0xa66cdB758e52F51325987b8eE11119019540B5fb
