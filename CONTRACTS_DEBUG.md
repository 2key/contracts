### Debug Acquisition Contract


##### Event source -> Acquisition not wired 
```
Connect remix instance with your localhost
Guide : https://remix.readthedocs.io/en/latest/tutorial_remixd_filesystem.html
Find under localhost/2key TwoKeyEventSource.sol contract
Compile it with 0.4.24 commit compiler
Make sure you're using ropsten network in your metamask
Under run tab on the right, choose network to be InjectedWeb3 (Ropsten)
After that, from dropdown menu under that select TwoKeyEventSource contract 
Press 'at address' and paste the address of the deployed TwoKeyEventSource
After that call 'isAddressWhitelistedToEmitEvents' with address of Acquisition campaign
```
1. If the response is `true` then this is not an issue
2. Otherwise, ping moderator or admin (Nikola/Eitan/Andrii) to update event source

##### TwoKeyExchangeRate - not set rate yet
```$xslt
Connect remix instance with your localhost
Guide : https://remix.readthedocs.io/en/latest/tutorial_remixd_filesystem.html
Find under localhost/2key TwoKeyExchangeRateContract.sol contract
Compile it with 0.4.24 commit compiler
Make sure you're using ropsten network in your metamask
Under run tab on the right, choose network to be InjectedWeb3 (Ropsten)
After that, from dropdown menu under that select TwoKeyExchangeRateContract contract 
Press 'at address' and paste the address of the deployed TwoKeyExchangeRateContract
After that call 'getFiatCurrencyDetails' function with "USD" as param
```
1. If you get the response with `real values` (Timestamp != 0) then this is not an issue
2. Otherwise, ping David/Eitan to run lambdas to update this




