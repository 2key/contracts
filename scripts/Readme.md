### How to generate transaction bytecodes

Make sure you're using >= 3.6 python version on your machine

```apple js
pip install web3
pip install eth_abi
```

##### Generate bytecode for sending tokens:
- Arguments: 
    - receiver_address (The one who has to receive tokens) (unit -> regular number)
    - amount

`python generate_bytecode.py transfer2KeyTokens <receiver_address> <amount>`

##### Generate bytecode for upgrading contract:
- Arguments:
    - contract_name
    - contract_version
    
`python generate_bytecode.py upgradeContract <contract_name> <contract_version>`


##### Generate bytecode for changing rewards release date:
- Arguments:
    - new_date
  
`python generate_bytecode.py setNewTwoKeyRewardsReleaseDate <new_date>`


##### Generate bytecode for adding a member to congress:
- Arguments:
    - target_member (member address)
    - member_name (member name --> bytes32 format))
    - voting_power (member voting power)
  
`python generate_bytecode.py addMember <target_member> <member_name> <voting_power>`

##### Generate bytecode for removing a member from congress:
- Arguments:
    - target_member (member address)
 
`python generate_bytecode.py removeMember <target_member>`



