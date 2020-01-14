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

echo "Generating bytecodes for patching plasma contracts"
cd ../..
echo "Patch CPC_PLASMA campaign to 1.0.12"
python3 generate_bytecode.py approveNewCampaign CPC_PLASMA 1.0.12
