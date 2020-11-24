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

echo "Destination for execution: 0xc96a16b5064797a883f12780400a5e8e5d5d4d20"
python3 generate_bytecode.py upgradeContract TwoKeyPlasmaParticipationRewards 1.0.6



echo "Destination for execution is TwoKeyPlasmaParticipationRewards address: 0xc8f19c88c9335880d8c4a165acdb7499f444dc6d"
python3 generate_bytecode.py redeclareEpochRewards 3 2720000000000001285884

