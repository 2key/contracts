#### How to calculate arguments for APR when maintaining it
- Set the amount of ETH to be in the reserve **(initial_ether_amount)**
- Get ETH -> DAI rate on kyber swap **(eth/dai)**
- Get latest rate for DAI -> 2KEY either from the TwoKeyUpgradableExchange.sol 
or some centralized exchange **(dai/2key)**
- Compute the amount of 2KEY which will match the corresponding value of **(initial_ether_amount)**:
`**amount_of_2KEY** = **initial_ether_amount** * **(eth/dai)** / **(dai/2key)**
- Derive the `initial_price` = `initial_ether_amount/amount_of_2KEY`
- Set `pMin` (minimal supported price factor)
- Set `pMax` (maximal supported price factor)
- Derive the `liquidity_rate` : ` ln(1 / pMin) / initial_ether_amount`
- Derive initial token amount : ` (pMax-1)/(pMax * liquidty_rate * initial_price) ` 

 Then make sure you have access to repository: (if not clone it)
 ```$xslt
$ git clone https://github.com/2key/smart-contracts.git
$ cd smart-contracts/scripts
```  
 After all the values are computed, you can go to the smart-contracts (kyber) repository, and edit the 
 `/smart-contracts/scripts/liquidity_input_params.json`
 
 To compute the values for the `setLiquidityParams` you should run in the same directory:  
 -  Make sure you have numpy installed, if not run (`$ pip3 install numpy`)
 - `$ python3 get_liquidity_params.py --input liquidity_input_params.json --get params`

**_This is how the output should look like:**_ 

```angular2html
_rInFp: 10995116277
_pMinInFp: 57437387
_numFpBits: 40
_maxCapBuyInWei: 5000000000000000000
_maxCapSellInWei: 5000000000000000000
_feeInBps: 30
_maxTokenToEthRateInPrecision: 208956000000000
_minTokenToEthRateInPrecision: 52239000000000
```

#### How to change on-going reserve with some params

- First of all need to run `disableTrade()` function in KyberReserve contract. That
can be done by calling the following bytecode generator 
and executing it through `TwoKeyCongress.sol`: `$ python3 generate_bytecode disableKyberTrade`
- After Kyber trade is disabled, for the rebalancing you need to pull ETH from contract (leave how much you want)
That can be done by calling the following bytecode generator and executing it through `TwoKeyCongress.sol`:
 `$ python3 generate_bytecode withdrawEtherFromReserve <kyber_reserve_address> <amount_in_wei>`
- Then again `setLiquidityParams` should be called
- After all, we must make sure to enable trade in Kyber by calling 
 `enableTrade()` function in KyberReserve contract. 

