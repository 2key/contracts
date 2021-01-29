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

echo "Destination for execution is TwoKeyPlasmaParticipationRewards address: 0xc8f19c88c9335880d8c4a165acdb7499f444dc6d"
python3 generate_bytecode.py redeclareEpochRewards 10 650999999999999213568