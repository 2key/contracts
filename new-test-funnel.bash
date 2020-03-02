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


echo "Sending some eth to addresses"
yarn run test:one 2key-protocol/test/unitTests/envRelatedTests/sendETH.spec.ts
spinner 2
echo "Testing congress voting and sending ether"
yarn run test:one 2key-protocol/test/unitTests/envRelatedTests/congressVote.spec.ts
#spinner 2
#echo "Testing user creation, all errors will be skipped and displayed in console"
#yarn run test:one 2key-protocol/test/unitTests/envRelatedTests/runUserRegistration.spec.ts
#spinner 2
#echo "Testing setting the rates for the contracts"
#yarn run test:one 2key-protocol/test/unitTests/envRelatedTests/twoKeyExchangeRate.spec.ts
spinner 2
echo "Running acquisition test"
#node -r dotenv/config ./node_modules/.bin/mocha --exit --bail -r ts-node/register 2key-protocol/test/campaignsTests/exampleAcquisitionTest.ts
#node -r dotenv/config ./node_modules/.bin/mocha --exit --bail -r ts-node/register 2key-protocol/test/campaignsTests/mvp/test7.spec.ts
node -r dotenv/config ./node_modules/.bin/mocha --exit --bail -r ts-node/register 2key-protocol/test/campaignsTests/mvp/*.spec.ts
node -r dotenv/config ./node_modules/.bin/mocha --exit --bail -r ts-node/register 2key-protocol/test/campaignsTests/withCampaignBonus/*.spec.ts
node -r dotenv/config ./node_modules/.bin/mocha --exit --bail -r ts-node/register 2key-protocol/test/campaignsTests/withoutCampaignBonus/*.spec.ts

