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

python3 generate_bytecode.py declareEpochs "34,35,36,37,38,39,40,41,42" "88182000000000078643200,98182000000000078643200,98182000000000078643200,98182000000000078643200,98182000000000078643200,98182000000000078643200,98182000000000078643200,98182000000000078643200,98182000000000078643200"





