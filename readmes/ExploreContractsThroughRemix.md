### Step by step guide to explore contract state through remix

```
Connect remix instance with your localhost
Guide : https://remix.readthedocs.io/en/latest/tutorial_remixd_filesystem.html
Find under localhost/2key all contracts
Compile it with 0.4.24 commit compiler
```

- Depending on network you want open MM and select it.
- If you want to explore contracts on plasma network:


```
Open MM and select option under networks : CUSTOM RPC
Add: https://rpc.private.test.k8s.2key.net as network
Save
```

After finishing, compile contracts, and after that load contract at address from plasma network.