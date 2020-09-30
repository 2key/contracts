#!/bin/bash

printf "1. Extract latest contracts from 2key-protocol \n"
rm -rf build/
yarn run deploy --extract


start=`date +%s`

printf "\n 2. Run verification script"
node verifyDeployment.js

end=`date +%s`
runtime=$((end-start))

printf "\n ✨ Done is $runtime seconds. ✨"

