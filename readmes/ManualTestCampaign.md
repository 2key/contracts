# Accounts

coinbase - accounts[0]
inventoryOwner - accounts[1]
campaignCreator - accounts[2]
contractor - accounts[3]
moderator - accounts[4]
converter - accounts[5]
anybody - accounts[6]

tokenIndex - 3

# Preparation

1. coinbase deploys TwoKeyEconomy 
2. coinbase deploys ERC20TokenMock - it will be the asset we play with
2. coinbase deploys TwoKeyEventSource
3. coinbse deploys TwoKeyWhitelisted as whitelistInfluencer
4. coinbse deploys TwoKeyWhitelisted as whitelistConverter
5. coinbase transfers to inventoryOwner 100000 tokens by calling transfer in ERC20TokenMock
6. campaignCreator deploys TwoKeyCampaign, set:
  * the openingTime to web3.eth.getBlock('latest').timestamp 
  * closing time to 2 hours after that, web3.eth.getBlock('latest').timestamp + 2 * 60 * 60
  * escrowPrecentage to 10
  * maxPi 30
  * rate 2 
  * expireConversion to 20 (20 minutes)

# Test

## Add Fungible Asset When Open

1. inventoryOwner approves 80000 to factory contract, by calling Approve in ERC20TokenMock
2. inventoryOwner calls addFungibleChild on factory adding under tokenIndex, 5000 of ERC20TokenMock
3. should succeed

## Transfer By Controller When Converter Not Whitelisted

1. moderator calls transferFungibleChild to transfer 3000 of tokenIndex to converter
2. should fail

## Transfer By Controller When Converter Whitelisted

1. coinbase calls addToWhitelist for converter
2. moderator calls transferFungibleChild to transfer 3000 of tokenIndex to converter
3. should succeed

## Transfer By Controller When Buyer Not Whitelisted

1. moderator calls transferFungibleChild to transfer 3000 of tokenIndex to buyer
2. should fail

## Transfer By Controller When Buyer Whitelisted

1. coinbase calls addToWhitelist for buyer
2. moderator calls transferFungibleChild to transfer 3000 of tokenIndex to buyer
3. should succeed

## Transfer by Anybody

1. anybody calls transferFungibleChild to transfer 100 of tokenIndex to buyer
3. should fail

## Cancel by Controller

1. contractor calls cancelFungibleChildTwoKey to target for 2000 of ERC20Mock
2. should succeed

## Cancel by Anybody

1. anybody calls cancelFungibleChildTwoKey to target for 2000 of ERC20Mock
2. should fail

