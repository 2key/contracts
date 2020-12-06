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
echo "Destination for execution: 0xd0043ac71897032d572580ad84359323b5719068"
cd ../..

python3 generate_bytecode.py upgradeContract TwoKeyPlasmaRegistry 1.0.5
python3 generate_bytecode.py upgradeContract TwoKeyPlasmaEventSource 1.0.4
python3 generate_bytecode.py upgradeContract TwoKeyPlasmaReputationRegistry 1.0.3
python3 generate_bytecode.py approveNewCampaign CPC_PLASMA 1.0.10



echo "Setting signatory address on TwoKeyPlasmaParticipationRewards contract."
echo "Destination for execution: 0xfd5e5de4787b301739e05853ba31dd194e4f180c"
python3 generate_bytecode.py setSignatoryAddress 0x2cd223bd2d9d0b9eded76a881d03dad530ea4400






