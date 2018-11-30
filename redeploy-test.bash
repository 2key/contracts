#!/bin/bash

spinner() {
    chars="/-\|"

    for (( j=0; j< $1; j++ )); do
      for (( i=0; i<${#chars}; i++ )); do
        sleep 0.5
        echo -en "${chars:$i:1}" "\r"
      done
    done
}

spinner 4
echo "Redeploying contracts to dev-local"
yarn run deploy --migrate dev-local --reset
spinner 4
echo "Sending some eth to addresses"
yarn run test:one 2key-protocol/test/sendETH.spec.ts
spinner 4
echo "Running test to fill some data to 2key-reg"
yarn run test:one 2key-protocol/test/updateTwoKeyReg.dev.spec.ts
spinner 4
echo "Running test"
yarn run test