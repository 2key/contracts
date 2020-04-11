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

echo "Destination for execution is TwoKeyAdmin address : 0x8430db5eba7745eab1904d173129b7965190055a"

cd ../..

python3 generate_bytecode.py setLiquidityParamsKyber 0xC4Fdb3e0399f11959DDD53E356bbA18A2A780AB4 7696581394 27487790 40 5000000000000000000 5000000000000000000 25 100000000000000 25000000000000




