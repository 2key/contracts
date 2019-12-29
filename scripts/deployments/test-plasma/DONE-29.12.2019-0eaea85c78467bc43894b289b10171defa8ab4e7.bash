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
echo "TwoKeyCPCCampaignPlasma patch to version 1.0.11"
echo "TwoKeyPlasmaEvents patch to version 1.0.5"
echo "TwoKeyPlasmaFactory patch to version 1.0.3"
echo "TwoKeyPlasmaRegistry patch to version 1.0.1"

echo "Destination for execution: 0xc96a16b5064797a883f12780400a5e8e5d5d4d20"
cd ../..

python3 generate_bytecode.py approveNewCampaign CPC_PLASMA 1.0.11
python3 generate_bytecode.py upgradeContract TwoKeyPlasmaEvents 1.0.5
python3 generate_bytecode.py upgradeContract TwoKeyPlasmaFactory 1.0.3
python3 generate_bytecode.py upgradeContract TwoKeyPlasmaRegistry 1.0.1
