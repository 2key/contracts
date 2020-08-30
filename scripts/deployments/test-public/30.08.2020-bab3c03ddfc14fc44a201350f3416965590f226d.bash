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
echo "Generating bytecodes for changes on public network"
echo "Destination for execution of contracts patches: 0xf4797416e6b6835114390591d3ac6a531a061396"
cd ../..

python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.32
python3 generate_bytecode.py upgradeContract TwoKeyEventSource 1.0.15
python3 generate_bytecode.py upgradeContract TwoKeyExchangeRateContract 1.0.2
python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.26
python3 generate_bytecode.py upgradeContract TwoKeyBudgetCampaignsPaymentsHandler 1.0.1
python3 generate_bytecode.py approveNewCampaign CPC_PUBLIC 1.0.53


