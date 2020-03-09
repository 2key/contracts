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

echo "Set 2KEY tokens release date to 20th April 2020 (UNIX = 1587384000)"
echo "TwoKeyAdmin contract proxy address on production: 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"
cd ../..

python3 generate_bytecode.py setNewTwoKeyRewardsReleaseDate 1587384000

