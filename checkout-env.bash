#!/bin/bash

# Search in args which branch to checkout
for i in "$@"
do
case $i in
    -b=*|--branch=*)
    BRANCH="${i#*=}"
    ;;
    *)
            # unknown option
    ;;
esac
done
echo BRANCH = ${BRANCH}

git checkout staging
cd 2key-protocol/src
git checkout staging
cd ..
cd dist
git checkout staging
cd ../..
