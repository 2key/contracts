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
echo "Destination for execution: 0xf4797416e6b6835114390591d3ac6a531a061396"
cd ../..

python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.7
python3 generate_bytecode.py upgradeContract TwoKeyFeeManager 1.0.6
python3 generate_bytecode.py upgradeContract TwoKeyEventSource 1.0.8
python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.2
python3 generate_bytecode.py upgradeContract TwoKeyNetworkGrowthFund 1.0.1
python3 generate_bytecode.py approveNewCampaign DONATION 1.0.18
python3 generate_bytecode.py approveNewCampaign TOKEN_SELL 1.0.18





