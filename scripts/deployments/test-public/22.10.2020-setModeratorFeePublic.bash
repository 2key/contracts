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
echo "Destination for execution on public is TwoKeyAdmin contract: 0x8430db5eba7745eab1904d173129b7965190055a"
python3 generate_bytecode.py setModeratorFeePublic 10





