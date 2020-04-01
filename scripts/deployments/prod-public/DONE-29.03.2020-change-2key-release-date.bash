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

echo "Set 2KEY tokens release date to 12th May 12:01pm noon 2020 (UNIX = 1589284860)"
echo "TwoKeyAdmin contract proxy address on production: 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"
cd ../..

python3 generate_bytecode.py setNewTwoKeyRewardsReleaseDate 1589284860

