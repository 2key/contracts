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


echo "Destination for execution on plasma is TwoKeyPlasmaParticipationRewards contract: 0xbe2dcd00bd73a91278b5a1b3153d65b2f1f46548"
python3 generate_bytecode.py declareEpochs "16" "4021999999999997902848"