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

echo "TwoKeyPlasmaEvents patch to 1.0.2"
echo "TwoKeyPlasmaRegistry patch to 1.0.2"

echo "Destination for execution: 0xd0043ac71897032d572580ad84359323b5719068"
cd ../..

python3 generate_bytecode.py upgradeContract TwoKeyPlasmaEvents 1.0.3
python3 generate_bytecode.py approveNewCampaign CPC_PLASMA 1.0.1

