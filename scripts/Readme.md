### How to generate transaction bytecodes

Make sure you're using >= 3.6 python version on your machine

```apple js
pip install web3
pip install eth_abi
```

##### Generate bytecode for sending tokens:
- Arguments: 
    - receiver_address (The one who has to receive tokens)
    - amount 

`python generate_bytecode.py <receiver_address> <amount>`
