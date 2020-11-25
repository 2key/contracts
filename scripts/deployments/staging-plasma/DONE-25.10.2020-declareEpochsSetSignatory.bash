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
python3 generate_bytecode.py setSignatoryAddress 0xd43f37e636a5b434827ea315b72642e5f00d7bdb
python3 generate_bytecode.py declareEpochs "1,2,3,4,5,6,7,8,9" "1681999999999999528136,3450999999999998637576,4042000000000004794800,4950999999999992146216,4771000000000003683288,1582000000000000570956,3650999999999995794368,4361999999999995206704,2641999999999996641836"
