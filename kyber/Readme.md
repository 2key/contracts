#### How to run initial setup of Kyber contracts

- `$ git clone https://github.com/2key/smart-contracts.git`
- `$ cd smart-contracts/scripts`
- Open `liquidity_input_params.json` and checksum the values being set
- Make sure you have numpy installed, if not run (`$ pip3 install numpy`)
- Run `$ python3 get_liquidity_params.py --input liquidity_input_params.json --get params`
- Checksum the output in the console (should be like this - example)

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

- Go to 2key/contracts repository
- `$ cd scripts/deployments/test-public`
- `Checksum that the values passed in the script 11.04.2020-setLiquidityParams-kyber.bash are matching the ones you got in the log`
- Execute the script `$ bash ./11.04.2020-setLiquidityParams-kyber.bash`
