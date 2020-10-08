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
echo "Generating bytecode for method registerParticipationMiningEpoch(epochId,amount)"
echo "Destination for execution is TwoKeyParticipationMiningPool: 0xa6b9ee17f7281f2a6d327ddea2ae812c7439ef36"
cd ../..

python3 generate_bytecode.py generateNewParticipationEpoch <EPOCHID> <AMOUNT_WEI>


