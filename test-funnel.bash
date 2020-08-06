#!/bin/bash

test
testsPath='2key-protocol/test/campaignsTests/variations/**/*.spec.ts'

while test $# -gt 0; do
  case "$1" in
  --cpc)
    shift
    testsPath='2key-protocol/test/campaignsTests/variations/cpc/*.spec.ts'
    shift
    ;;
  --cpcNoRewards)
    shift
    testsPath='2key-protocol/test/campaignsTests/variations/cpcNoRewards/*.spec.ts'
    shift
    ;;
  --mvp)
    shift
    testsPath='2key-protocol/test/campaignsTests/variations/mvp/*.spec.ts'
    shift
    ;;
  --donation)
    shift
    echo "Donation tests aren't implmented yet"
    exit 1;
    shift
    ;;
  --acquisition)
    shift
    testsPath='2key-protocol/test/campaignsTests/variations/acquisition/**/*.spec.ts'
    shift
    ;;
  --example)
    shift
    testsPath='2key-protocol/test/campaignsTests/examples/*.ts'
    shift
    ;;
  *)
    break
    ;;
  esac
done

yarn run test:command 2key-protocol/test/unitTests/envRelatedTests/sendETH.spec.ts
yarn run test:command 2key-protocol/test/unitTests/envRelatedTests/congressVote.spec.ts
yarn run test:command 2key-protocol/test/unitTests/envRelatedTests/runUserRegistration.spec.ts
yarn run test:command 2key-protocol/test/unitTests/envRelatedTests/twoKeyExchangeRate.spec.ts

yarn run test:command "$testsPath"
