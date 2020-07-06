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






cd ../..
echo "Destination for execution is TwoKeySingletonsRegistry address: 0xf4797416e6b6835114390591d3ac6a531a061396"
python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.18
echo "Destination for execution is TwoKeyAdmin address : 0x8430db5eba7745eab1904d173129b7965190055a"
python3 generate_bytecode.py setContracts 0xC4Fdb3e0399f11959DDD53E356bbA18A2A780AB4 0x920B322D4B8BAB34fb6233646F5c87F87e79952b 0x3b9140e6a74b7ca28b9dbd1fd3413ee5aaa1cc2a 0x0000000000000000000000000000000000000000
