# Accounts

coinbase - accounts[0]
inventoryOwner - accounts[1]
factoryCreator - accounts[2]
target - accounts[3]
admin - accounts[4]
anybody - accounts[5]
tokenIndex - 3

# Preparation

1. Deploy ERC20TokenMock - it will be the asset we play with, deployed 
by coinbase
2. Transfer to inventoryOwner 100000 tokens by calling transfer in ERC20TokenMock by coinbase
3. Deploy ComposableAssetFactory by factoryCreator, set the openingTime to web3.eth.getBlock('latest').timestamp and the closing time to 30 minutes after that, web3.eth.getBlock('latest').timestamp + 30 * 60

# Test

## Add Fungible Asset When Open

1. inventoryOwner approves 80000 to factory contract, by calling Approve in ERC20TokenMock
2. inventoryOwner calls addFungibleChild on factory adding under tokenIndex, 5000 of ERC20TokenMock
3. should succeed

## Add Fungible Asset When Closed

1. Wait after closing time
2. inventoryOwner calls addFungibleChild on factory adding under tokenIndex, 5000 of ERC20TokenMock
3. should fail

## Transfer By Admin

1. factoryCreator calls adminAddRole(admin, "controller") in order to make an admin have a controller role
2. admin calls transferFungibleChild to transfer 3000 of tokenIndex to target
3. should succeed

## Transfer by Anybody

1. anybody calls transferFungibleChild to transfer 100 of tokenIndex to target
3. should fail

## Expire

1. admin calls expireFungible to target for 2000 of ERC20Mock
2. should succeed

