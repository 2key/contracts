In order to deploy smart contracts and release protocol version following steps are required:
1. Make sure you have installed all node modules by running `yarn`
2. Make sure you have pulled all 3 repos (root, src, dist)
3. Then run from command line `git reset HEAD --hard` to make sure all unsynced files are dropped
(Run this in all 3 repos)
4. Then depending on network you want to deploy to pick the following:
    4. In case of hard reset with ledger run: `yarn run deploy private.test.k8s-dev,public.test.k8s-dev --reset`
