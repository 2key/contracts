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

python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.19
python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.15
python3 generate_bytecode.py upgradeContract TwoKeyEventSource 1.0.6
python3 generate_bytecode.py upgradeContract TwoKeyBudgetCampaignsPaymentsHandler 1.0.3





