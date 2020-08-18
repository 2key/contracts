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


echo "Set liquidity params through TwoKeyAdmin contract on Kyber network"

echo "Destination for execution is TwoKeyAdmin address : 0x31cf9c7847c979313fe27eadfcc847a8a0252d86"

cd ../..

python3 generate_bytecode.py setLiquidityParamsKyber 0x063453e3ed9ded626324C2CB9C72e062E4d7089E 17328061361 134193358 40 20000000000000000000 2000000000000000000 15 4068271611000000 122048148330000

