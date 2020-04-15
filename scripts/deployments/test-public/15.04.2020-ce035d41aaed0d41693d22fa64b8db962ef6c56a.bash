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


echo "TwoKeyAdmin new version:                    1.0.15"
echo "TwoKeyRegistry new version:                  1.0.5"
echo "TOKEN_SELL campaign new version:            1.0.35"




echo "Destination for execution: 0xf4797416e6b6835114390591d3ac6a531a061396"

cd ../..

python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.15
python3 generate_bytecode.py upgradeContract TwoKeyRegistry 1.0.5
python3 generate_bytecode.py approveNewCampaign TOKEN_SELL 1.0.35




