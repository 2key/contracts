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


echo "Kyber APR maintainance"
echo "Destination for execution is TwoKeyAdmin address : 0x8430db5eba7745eab1904d173129b7965190055a"

cd ../..

python3 generate_bytecode.py disableKyberTrade 0xC4Fdb3e0399f11959DDD53E356bbA18A2A780AB4
python3 generate_bytecode.py withdrawEtherFromReserve 0xC4Fdb3e0399f11959DDD53E356bbA18A2A780AB4 69000000000000000000
python3 generate_bytecode.py setLiquidityParamsKyber 0x3B9140E6a74B7cA28B9dBD1fD3413Ee5aaa1CC2A 10887584040 58274116 40 2000000000000000000 1000000000000000000 30 530000000000000 53000000000000
python3 generate_bytecode.py enableKyberTrade 0xC4Fdb3e0399f11959DDD53E356bbA18A2A780AB4

