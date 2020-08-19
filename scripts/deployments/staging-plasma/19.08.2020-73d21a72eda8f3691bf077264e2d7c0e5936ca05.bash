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

echo "Destination for execution: 0x8a84df5f7ed68f7087c9e3f54b49259c37726560"

cd ../..

python3 generate_bytecode.py approveNewCampaign CPC_PLASMA 1.0.15
python3 generate_bytecode.py approveNewCampaign CPC_NO_REWARDS_PLASMA 1.0.1

