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

echo "Destination for execution: 0xc96a16b5064797a883f12780400a5e8e5d5d4d20"

cd ../..

python3 generate_bytecode.py approveNewCampaign CPC_PLASMA 1.0.43

