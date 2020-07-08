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

python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.10
python3 generate_bytecode.py upgradeContract TwoKeyFeeManager 1.0.5
python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.8
python3 generate_bytecode.py approveNewCampaign CPC_PUBLIC 1.0.2


echo "Destination for 1 time functions: "

echo "Destination for execution of 1 time function calls: 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"

python3 generate_bytecode.py setKyberReserveContract 0x00Cd2388C86C960A646D640bE44FC8F83b78cEC9
python3 generate_bytecode.py migrateFeeManagerState




