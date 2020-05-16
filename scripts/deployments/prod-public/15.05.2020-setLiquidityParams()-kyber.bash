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

python3 generate_bytecode.py setLiquidityParamsKyber 0x063453e3ed9ded626324C2CB9C72e062E4d7089E 8395540936 119200254 40 5000000000000000000 1000000000000000000 35 8130900000000000 108412000000000
python3 generate_bytecode.py withdrawEtherFromReserve 0x00Cd2388C86C960A646D640bE44FC8F83b78cEC9 1000000000000000000
python3 generate_bytecode.py withdrawTokensFromReserve 0x00Cd2388C86C960A646D640bE44FC8F83b78cEC9 0xe48972fcd82a274411c01834e2f031d4377fa2c0 10000000000000000000 0xd19b86369f0da8692774773e84d5a01394c02cf7

