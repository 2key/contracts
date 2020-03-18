#!/bin/bash

test
testsPath='2key-protocol/test/campaignsTests/vairations/**/*.spec.ts'

while test $# -gt 0; do
  case "$1" in
  --cpc)
    shift
    testsPath='2key-protocol/test/campaignsTests/vairations/cpc/*.spec.ts'
    shift
    ;;
  --mvp)
    shift
    testsPath='2key-protocol/test/campaignsTests/vairations/mvp/*.spec.ts'
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
    testsPath='2key-protocol/test/campaignsTests/vairations/acquisition/**/*.spec.ts'
    shift
    ;;
  --example)
    shift
    testsPath='2key-protocol/test/campaignsTests/*.ts'
    shift
    ;;
  *)
    break
    ;;
  esac
done

yarn run test:command 2key-protocol/test/unitTests/envRelatedTests/*.spec.ts

yarn run test:command "$testsPath"
