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

echo "Destination for execution on plasma is TwoKeyPlasmaParticipationRewards contract: 0xfd5e5de4787b301739e05853ba31dd194e4f180c"

python3 generate_bytecode.py declareEpochs "23" "41951000000000002883584"


