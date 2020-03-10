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
echo BRANCH_TO_CHECKOUT = ${BRANCH}

git checkout BRANCH
cd 2key-protocol/src
git checkout BRANCH
cd ..
cd dist
git checkout BRANCH
cd ../..
