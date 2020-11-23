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

echo "Destination for execution on plasma is TwoKeyPlasmaParticipationRewards contract: 0xc8f19c88c9335880d8c4a165acdb7499f444dc6d"

python3 generate_bytecode.py declareEpochs "2" "10130000000000000000000"
python3 generate_bytecode.py declareEpochs "3" "2720000000000000000000"
python3 generate_bytecode.py declareEpochs "4" "2250000000000000000000"




