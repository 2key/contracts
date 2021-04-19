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
python3 generate_bytecode.py declareEpochs "17,18,19,20,21,22,23,24,25,26,27" "3951000000000003407872,2661999999999999475712,722000000000000000000,471000000000000458752,2662000000000002097152,4550999999999998689280,2750999999999998164992,831000000000000917504,2630999999999998164992,2942000000000000524288,1342000000000000524288"