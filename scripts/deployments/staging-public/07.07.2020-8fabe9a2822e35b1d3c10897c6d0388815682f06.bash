#!/usr/bin/env bash
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
echo "Destination for execution: 0x178a57d07d77bd6e2de7236d67a399e2f10c46d9"
cd ../..


python3 generate_bytecode.py upgradeContract TwoKeyBaseReputationRegistry 1.0.1
python3 generate_bytecode.py upgradeContract TwoKeyFeeManager 1.0.5
python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.11
python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.11
python3 generate_bytecode.py approveNewCampaign CPC_PUBLIC 1.0.13

echo "Destination is TwoKeyAdmin: 0x5eb1949424999327093d7a06619fc24170a9864e"
python3 generate_bytecode.py setContracts 0xdAfF796B4D657AA40E879BBBf3C5653392275E77 0x920B322D4B8BAB34fb6233646F5c87F87e79952b 0xfa3dee770dfa7be73d8be2664e41dd8ae75c74b6 0x0000000000000000000000000000000000000000


