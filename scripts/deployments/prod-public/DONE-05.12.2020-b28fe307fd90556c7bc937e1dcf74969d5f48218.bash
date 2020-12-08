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


echo "Destination for execution: 0x60ece4a5be3fd7594e9f24c2948cce5ce3c6dde7"

cd ../..

echo "Bytecodes for upgrading contracts: "

python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.21
python3 generate_bytecode.py upgradeContract TwoKeyEventSource 1.0.7
python3 generate_bytecode.py upgradeContract TwoKeyParticipationMiningPool 1.0.2
python3 generate_bytecode.py upgradeContract TwoKeyParticipationPaymentsManager 1.0.1
python3 generate_bytecode.py approveNewCampaign TOKEN_SELL 1.0.7
python3 generate_bytecode.py approveNewCampaign DONATION 1.0.7


echo "Setting signatory address on TwoKeyParticipationMiningPool contract."
echo "Destination for execution: 0x5410a315ff0558c7a2013a8f04a68f50c42403ee"
python3 generate_bytecode.py setSignatoryAddress 0x2cd223bd2d9d0b9eded76a881d03dad530ea4400



