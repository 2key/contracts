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

python3 generate_bytecode.py removeMember 0xca765a5794fd0a7b9fce58d6970771a7037ce1d9
python3 generate_bytecode.py addMember 0xca765a5794fd0a7b9fce58d6970771a7037ce1d9 "pcx1" 100
python3 generate_bytecode.py removeMember 0xf49ad6398e27dd0124a06e5109b8eab7f2e2577e
python3 generate_bytecode.py addMember 0xf49ad6398e27dd0124a06e5109b8eab7f2e2577e "pcx2" 100
python3 generate_bytecode.py removeMember 0x540b4809e058b370f40596108b2574d82ea2e5a4
python3 generate_bytecode.py addMember 0x540b4809e058b370f40596108b2574d82ea2e5a4 "pcx3" 100




