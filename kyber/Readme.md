#### How to run initial setup of Kyber contracts

- `$ git clone https://github.com/2key/smart-contracts.git`
- `cd smart-contracts/scripts`
- Open `liquidity_input_params.json` and checksum the values being set
- Run `python3 get_liquidity_params.py --input liquidity_input_params.json --get params`
- Checksum the output in the console (should be like this - example)
```angular2html
_rInFp: 7696581394
_pMinInFp: 27487790
_numFpBits: 40
_maxCapBuyInWei: 5000000000000000000
_maxCapSellInWei: 5000000000000000000
_feeInBps: 25
_maxTokenToEthRateInPrecision: 100000000000000
_minTokenToEthRateInPrecision: 25000000000000
```

- Go to 2key/contracts repository
- `cd scripts`
