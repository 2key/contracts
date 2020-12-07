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

python3 generate_bytecode.py declareEpochs "1,2,3,4,5,6,7,8,9,10,11" "8387308263025866293380,51331000000000017402808,44302000000000025948768,37342000000000035341536,39630999999999989244272,40030999999999968783692,38510999999999950391088,39370999999999998059136,40131000000000076527240,40611000000000093556464,43342000000000035105400"


