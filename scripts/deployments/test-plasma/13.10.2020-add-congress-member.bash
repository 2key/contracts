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

echo "Destination for execution: 0x7986b5cb184988c91e3bb5ae4a64da50df29c093"

cd ../..

python3 generate_bytecode.py addMember <MEMBER_ADDRESS> <MEMBER_NAME> <VOTING_POWER>

python3 generate_bytecode.py removeMember <MEMBER_ADDRESS>

