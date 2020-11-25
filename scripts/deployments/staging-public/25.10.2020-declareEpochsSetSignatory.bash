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


echo "Destination for execution on plasma is TwoKeyParticipationMiningPool contract: 0x676b1f72d301ced9465893c410cb5c797fd721d4"
python3 generate_bytecode.py setSignatoryAddress 0xd43f37e636a5b434827ea315b72642e5f00d7bdb
