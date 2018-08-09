# Accounts

coinbase - accounts[0]
inventoryOwner - accounts[1]
campaignCreator - accounts[2]
contractor - accounts[3]
moderator - accounts[4]
buyer - accounts[5]
anybody - accounts[6]

tokenIndex - 3

# Preparation

1. Deploy ERC20TokenMock - it will be the asset we play with, deployed 
by coinbase
2. Deploy TwoKeyEventSource by coinbase
3. Deploy TwoKeyWhitelisted as whitelistInfluencer by coinbase
4. Deploy TwoKeyWhitelisted as whitelistConverter by coinbase
5. Transfer to inventoryOwner 100000 tokens by calling transfer in ERC20TokenMock by coinbase
6. Deploy TwoKeyCampaign by campaignCreator, set the openingTime to web3.eth.getBlock('latest').timestamp and the closing time to 30 minutes after that
7. inventoryOwner approves 80000 to factory contract, by calling Approve in ERC20TokenMock
8. inventoryOwner calls addFungibleChild on factory adding under tokenIndex, 5000 of ERC20TokenMock
9. coinbase deploys TwoKeyEconomy 

# Test

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

