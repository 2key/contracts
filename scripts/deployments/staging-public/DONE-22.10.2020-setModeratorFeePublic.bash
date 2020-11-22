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


echo "Destination for execution on public is TwoKeyAdmin contract: 0x5eb1949424999327093d7a06619fc24170a9864e"
cd ../..

python3 generate_bytecode.py setModeratorFeePublic 10





