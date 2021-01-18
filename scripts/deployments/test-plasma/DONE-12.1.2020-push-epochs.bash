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

python3 generate_bytecode.py declareEpochs "11,12,13,14,15,16" "1101999999999998427136,331000000000000262144,211000000000000163840,811000000000000000000,321999999999999868928,622000000000000393216"


