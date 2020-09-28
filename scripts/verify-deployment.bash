#!/bin/bash

echo "1. Extract latest contracts from 2key-protocol"
yarn run deploy --extract

echo "--------------------------------------------------------"

start=`date +%s`

echo "2. Run verification script"
node verifyDeployment.js

end=`date +%s`
runtime=$((end-start))

echo "✨ Done is $runtime seconds. ✨"

