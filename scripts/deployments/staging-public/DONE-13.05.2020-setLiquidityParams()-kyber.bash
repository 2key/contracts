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

echo "Destination for execution is TwoKeyAdmin address : 0x5eb1949424999327093d7a06619fc24170a9864e"

cd ../..

python3 generate_bytecode.py setLiquidityParamsKyber 0xFA3DEe770dfA7bE73D8BE2664e41dd8Ae75c74b6 6355177208 57793079 40 2000000000000000000 1000000000000000000 30 1051249999999999 52562500000000

