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

echo "Destination for execution is TwoKeyParticipationMiningPool address: 0xa6b9ee17f7281f2a6d327ddea2ae812c7439ef36"

python3 generate_bytecode.py setSignatoryAddress 0xd43f37e636a5b434827ea315b72642e5f00d7bdb

