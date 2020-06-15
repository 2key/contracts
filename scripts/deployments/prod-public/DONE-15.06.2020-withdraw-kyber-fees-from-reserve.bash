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


echo "Destination for execution is TwoKeyAdmin address : 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"

cd ../..

python3 generate_bytecode.py pullKyberFeesFromReserve 0x00Cd2388C86C960A646D640bE44FC8F83b78cEC9 0x063453e3ed9ded626324C2CB9C72e062E4d7089E

