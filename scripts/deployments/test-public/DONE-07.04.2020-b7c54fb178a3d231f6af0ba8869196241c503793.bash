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


echo "TwoKeyEventSource new version:                    1.0.10"
echo "TwoKeyFeeManager new version:                     1.0.10"




echo "Destination for execution: 0xf4797416e6b6835114390591d3ac6a531a061396"

cd ../..

python3 generate_bytecode.py upgradeContract TwoKeyEventSource 1.0.10
python3 generate_bytecode.py upgradeContract TwoKeyFeeManager 1.0.10




