### How to generate transaction bytecodes

Make sure you're using >= 3.6 python version on your machine

```apple js
pip install web3
pip install eth_abi
```

#### Generate bytecode for sending tokens:
- Arguments: 
    - receiver_address (The one who has to receive tokens)
    - amount  (unit -> regular number)

`python generate_bytecode.py transfer2KeyTokens <receiver_address> <amount>`

eg. "Lets transfer 500.5 tokens" 
- `python generate_bytecode.py transfer2KeyTokens 0x380249E32B620fbf2Fa53418B7141770524Da9C5 500.5`


#### Generate bytecode for upgrading contract:
- Arguments:
    - contract_name 
    - contract_version
    
`python generate_bytecode.py upgradeContract <contract_name> <contract_version>`

eg. "Lets upgrade TwoKeyUpgradableExchange contract to version 1.0.2" 
- `python generate_bytecode.py upgradeContract TwoKeyUpgradableExchange 1.0.2`


#### Generate bytecode for changing rewards release date:
- Arguments:
    - new_date
  
`python generate_bytecode.py setNewTwoKeyRewardsReleaseDate <new_date>`

eg. "Lets change rewards release date to 12428814231 timestamp"
- `python generate_bytecode.py setNewTwoKeyRewardsReleaseDate 12428814231`


#### Generate bytecode for adding a member to congress:
- Arguments:
    - target_member (member address)
    - member_name (member name --> bytes32 format))
    - voting_power (member voting power)
  
`python generate_bytecode.py addMember <target_member> <member_name> <voting_power>`

eg. "Lets add Nikola Madjarevic to congress and give him voting power 1. His address is 0x380249E32B620fbf2Fa53418B7141770524Da9C5"
- `python generate_bytecode.py addMember 0x380249E32B620fbf2Fa53418B7141770524Da9C5 0x4e696b6f6c61204d61646a617265766963000000000000000000000000000000 1`


#### Generate bytecode for removing a member from congress:
- Arguments:
    - target_member (member address)
 
`python generate_bytecode.py removeMember <target_member>`

eg. "Let's remove member with address 0x380249E32B620fbf2Fa53418B7141770524Da9C5 from congress"
- `python generate_bytecode.py removeMember 0x380249E32B620fbf2Fa53418B7141770524Da9C5`



