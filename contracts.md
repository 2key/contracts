Contracts are divided into three areas:

* campaign - running a campaign in 2key
* admin - the administration of 2key across all campaigns
* ico - 2key ico

# The Campaign

We introduce ComposableAssetFactory as a holder of the goods, be it ERC20, ERC721, or something else that can be represented as such to be sold in a campaign. A campaign is subclass of ComposableAssetFactory.

## CompsableAssetFactory

Based on [Introducing Crypto Composables](https://medium.com/coinmonks/introducing-crypto-composables-ee5701fde217)

Acts as a virtual store with a catalogue of assets. 
Holds assets Fungible (ERC20) or NonFungible (ERC721).
For each asset we store its type as Fungible or NonFungible.

It can handle these classes of assets:

1. Fungible - common ERC20 tokens or anything that is countable, such as freelance hours, or yoga lessons - where the asset is represented by a ERC20 contract in Ethereum
2. NonFungible - items in common ERC721 contracts, or any uniquely distinguishable assets such as player cards, or real-estate properties -  - where the asset is represented within ERC721 contract in Ethereum

We first add assets to it, where each addition of an asset involves a call to transfer the assets to the contract in the corresponding ERC20 or ERC721 contract. 

Then, the owner of the contract can transfer assets to whoever it wishes.

## Timed

A class for setting a duration for a contract. Modifiers to enable limited lifetime for 2key campaigns.

Derived from [Open Zeppelin TimedCrowdsale](https://openzeppelin.org/api/docs/crowdsale_validation_TimedCrowdsale.html)

Constructed with a start time and duration. 

## TimedCompsableAssetFactory

A ComposableAssetFactory which is Timed, with a start date and end date, beyond which one cannot add assets or transfer assets from it. At its expiry, the owner of the contract, can transfer all assets to itself.

## TwoKeyTypes

A contract providing an enum for the type of assets: Fungible and NonFungible

## TwoKeyEventSource

Acts as an event source - emitting all events on campaigns progress, and escrow progress.

This is needed so our backend can listen to events and keep a cache of events for the UI. 

For each event, there is function to emit that event.

## Campaign 

(What used to be called TwoKeyContract)

The campaign works by holding assets, tracking referrals, and upon conversion creating an escrow contract for the conversion. 

Payout in TwoKeyToken
Rewards in TwoKeyToken
No incentive model
Rewards are assigned only to the last referral chain

A campaign has an expiration period.

Influencers have to redeem rewards.

Rewards are in TwoKeyToken

In the case, of crowdsales, there are sub classes (see below) that do not require a transfer of assets to us. 

Influencers and converters are to be whitelisted

### Assets Promoted in Campaign

A campaign is a TimedComposableAssetFactory. As such, we first add assets to it, either Fungible or NonFungible.

We add functions for pricing:

1. setPriceFungible
2. setPriceNonFungible

### Referrals

To manage the referral process, a camapign is a StandardToken that has a supply of ARCs that are used to implement the incentive model.

This is implemented by the functions: 

1. transferQuota
2. transferFromQuota
3. transferFrom
4. transfer

### Conversion

The act of conversion creates an escrow contract to which the purchased asset is transferred. 

This is implemented by the functions: 

1. buyFromWithTwoKey - called by the converter
2. buyProductTwoKey - splits the handling of fungible and non fungible assets
2. fulfillFungibleTwoKeyToken - creating the escrow for fungible
3. fulfillNonFungibleTwoKeyToken - creating the escrow for non-fungible

### Rewards

This is implemented by the functions:

1. transferRewardsTwoKeyToken - called by ecrow when conversion approved and rewards should be delivered to influencers. Rewards are computed and assigned in an internal xbalances mapping.
2. redeemTwoKeyToken - an influencer cashes its reward

## CampaignETH

Like a campaign
Payout is in ETH. Hence the conversion area has a different set of functions.

### Conversion

The act of conversion creates an escrow ETH contract to which the purchased asset is transferred. In that escrow payout is in ETH.

This is implemented by the functions: 

1. buyFromWithETH - called by the converter
2. buyProductETH - splits the handling of fungible and non fungible assets
2. fulfillFungibleETH - creating the escrow for fungible
3. fulfillNonFungibleETH - creating the escrow for non-fungible

## Escrow

Upon a buy, we create an Escrow for the purchase.

Holds the purchased assets, till the moderator approves the purchase. 
Upon conversion, the payout is transferred to the contractor, the moderator receives its fee, and the campaign assigns rewards.

An escrow has an expiratin period, after which the asset is returned to the campaign.

## EscrowETH

Like Escrow
Works with CampaignETH, where payout is in ETH

# Using TwoKey Campaign for ICO

##  CrowdsaleWithTwoKey

A crowdsale that is used in a campaign

Any Crowdsale that inherits from it, will give whatever bonuses are due according to its engagement with TwoKey and will work with the campaign promoting it. 

Form this purpose, there is a whitelist, which includes the campaigns which receive bonus. The actual buyTokens is done from the campaign.

## TwoKeyCampaignCrowdsale

A campaign for a crowdsale working with Two Key

## TwoKeyCampaignETHCrowdsale

Like TwoKeyCampaignCrowdsale
But ETH campaign for a crowdsale working with Two Key

# Two Key Administration

Managing the TwoKey ecosystem

## TwoKeyWhitelisted

A whitelist for different needs

Adapted from [WhitelistedCrowdsle](https://openzeppelin.org/api/docs/crowdsale_validation_WhitelistedCrowdsale.html)

## TwoKeyCongress

A voting mechanism decided by a specified quoram and duration of debate.
A variation of [Ethereum democracy](https://www.ethereum.org/dao)

## TwoKeyEconomy

Our token economy
TwoKey ERC20 token

## TwoKeyAdmin

Two Key admin contract
Once created, we should transfer the ownership of Economy and Exchange to it

## TwoKeyReg

Stores the mapping from usernames to addresses

## TwoKeyUpgradableExchange

An exchange that can sell and buy token
A subclass of Crowdsale that can be upgraded
It has a fixed rate
There will be subclasses with floating rate.

## TwoKeyFixedRateExchange

A TwoKeyUpgradableExchange which has a fixed rate

## TwoKeyFloatingRateExchange

A TwoKeyUpgradableExchange whose rate can be updated

# TwoKey ICO

Contracts for our ICO

## TwoKeyPresellExchange 

A subclass of Crowdsale for Two Key ICO

Uses vesting to release tokens

## TwoKeyPresellVesting

Vesting to be used for Two Key ICO 

# Contracts for Tests

## BasicStorage

Stores and retrieve uint values

## ERC20TokenMock

Mocks a ERC20 token

## ERC721TokenMock

Mocks a ERC721 token





