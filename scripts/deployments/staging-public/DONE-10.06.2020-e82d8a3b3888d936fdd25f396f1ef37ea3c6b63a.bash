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


python3 generate_bytecode.py upgradeContract TwoKeyAdmin 1.0.10
python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.7
python3 generate_bytecode.py upgradeContract TwoKeyFeeManager 1.0.4
python3 generate_bytecode.py approveNewCampaign CPC_PUBLIC 1.0.9
python3 generate_bytecode.py approveNewCampaign TOKEN_SELL 1.0.22
python3 generate_bytecode.py approveNewCampaign DONATION 1.0.22


echo "Destination for execution of 1 time function calls: 0x5eb1949424999327093d7a06619fc24170a9864e"

python3 generate_bytecode.py setKyberReserveContract 0xdAfF796B4D657AA40E879BBBf3C5653392275E77
python3 generate_bytecode.py setSpread 30000000000000000
python3 generate_bytecode.py migrateFeeManagerState


