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

echo "Generating bytecodes for changes on plasma network"
echo "TwoKeyCPCCampaignPlasma patch to 1.0.1"
echo "Destination for execution: 0xe4dd40e6da89a5f8adc059ce9f0c5826daf32b64"
cd ../..
python3 generate_bytecode.py approveNewCampaign CPC_PLASMA 1.0.1
