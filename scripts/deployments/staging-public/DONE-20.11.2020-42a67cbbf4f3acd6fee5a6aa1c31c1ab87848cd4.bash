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


python3 generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.24
python3 generate_bytecode.py upgradeContract TwoKeyEventSource 1.0.12
python3 generate_bytecode.py upgradeContract TwoKeyParticipationMiningPool 1.0.4

