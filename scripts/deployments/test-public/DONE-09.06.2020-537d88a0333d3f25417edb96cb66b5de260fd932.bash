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

python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.23
python3 generate_bytecode.py upgradeContract TwoKeyFeeManager 1.0.14
python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.13
python3 generate_bytecode.py approveNewCampaign DONATION 1.0.35
python3 generate_bytecode.py approveNewCampaign TOKEN_SELL 1.0.37
python3 generate_bytecode.py approveNewCampaign CPC_PUBLIC 1.0.40


echo "Destination for execution of 1 time function calls: 0x8430db5eba7745eab1904d173129b7965190055a"

python3 generate_bytecode.py setKyberReserveContract 0xC4Fdb3e0399f11959DDD53E356bbA18A2A780AB4
python3 generate_bytecode.py setSpread 30000000000000000
python3 generate_bytecode.py migrateFeeManagerState


