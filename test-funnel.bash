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


spinner 2
echo "Sending some eth to addresses"
yarn run test:one 2key-protocol/test/unitTests/envRelatedTests/sendETH.spec.ts
spinner 2
echo "Testing congress voting and sending ether"
yarn run test:one 2key-protocol/test/unitTests/envRelatedTests/congressVote.spec.ts
spinner 2
echo "Testing user creation, all errors will be skipped and displayed in console"
yarn run test:one 2key-protocol/test/unitTests/envRelatedTests/runUserRegistration.spec.ts
spinner 2
echo "Testing setting the rates for the contracts"
yarn run test:one 2key-protocol/test/unitTests/envRelatedTests/twoKeyExchangeRate.spec.ts
spinner 2
echo "Running acquisition test"
yarn run test
spinner 2
echo "Running donation test"
yarn run test:donation
spinner 2
echo "Running CPC test"
yarn run test:cpc
spinner 2
echo "Bash script finished execution!"
