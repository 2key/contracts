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

echo "Destination for execution: 0xc455CFdF2aEE8D538dF2D6AF32c637Cfbd9e2E4a"

cd ../..

python3 generate_bytecode.py removeMember 0x5e2B2b278445AaA649a6b734B0945Bd9177F4F03
python3 generate_bytecode.py addMember 0x7bd96058c46892665c90bc440bc2dd5b542245fb "pcx1" 100
python3 generate_bytecode.py removeMember 0xD19b86369f0da8692774773E84D5A01394C02cF7
python3 generate_bytecode.py addMember 0xD19b86369f0da8692774773E84D5A01394C02cF7 "pcx2" 100


