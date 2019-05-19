#!/bin/bash

timestamp=$(date +%F_%T)
yarn run deploy --migrate $1 --reset make 2>&1 | tee "./deployment_logs/$1_$timestamp".txt
