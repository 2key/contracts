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

python3 generate_bytecode.py declareEpochs "5,6,7,8,9,10" "2470999999999997902388,1741999999999999730028,1881999999999995137508,1110999999999998958788,362000000000000436387,65099999999999922626"



