### Changelog Contracts Repository

##### TwoKeyAcquisitionCampaign
- Added a couple of optimizations, no such interface changes
- The notable one is change in method `function referrerWithdraw` where we'll work with both stable coins and 2key

##### TwoKeyAcquisitionLogicHandler
- Added a couple of optimizations, no such interface changes

##### TwoKeyConversionHandler
- Added mapping `doesConverterHaveExecutedConversions`
- Added `address public twoKeyPurchasesHandler`
- Added `ITwoKeyPurchasesHandler(twoKeyPurchasesHandler).startVesting`

- Deleted `mapping(address => address[]) converterToLockupContracts` 
- Deleted following fields (moved to PurchasesHandler)
```
    uint tokenDistributionDate; // January 1st 2019
    uint maxDistributionDateShiftInDays; // 180 days
    uint numberOfVestingPortions; // For example 6
    uint numberOfDaysBetweenPortions; // For example 30 days
    uint bonusTokensVestingStartShiftInDaysFromDistributionDate; // 180 days
```
- Deleted `lockupAddress` from Conversion object
- Deleted function 
```
function getLockupContractsForConverter(
        address _converter
    )
```
- Deleted function 
```
function getLockupContractAddress(
        uint _conversionId
    )
```

##### TwoKeyPurchasesHandler
This is completely new contract which will be in charge of handling vesting and token distribution once after conversion is executed.
Everything will be mapped by `conversionId` on this contract. This contract will be created every time new campaign is created.

Methods:
- Change token distribution date
```
function changeDistributionDate(
        uint _newDate
    )
    public
```
- Function to withdraw tokens
```
function withdrawTokens(
        uint conversionId,
        uint portion
    )
    public
```
- Function to get information about purchase (conversion)
```
function getPurchaseInformation(
        uint _conversionId
    )
```
The response for this function will look like this:
```
return (
            p.converter,
            p.baseTokens,
            p.bonusTokens,
            p.portionAmounts,
            p.isPortionWithdrawn,
            unlockingDates
        );
```

- Function to get static information from the contract `function getStaticInfo()`
- Function to get portion unlocking dates `function getPortionsUnlockingDates()`

##### library IncentiveModels
- Minor optimization to avoid potential `revert()`

##### TwoKeyCampaignValidator
- Added address of contract `twoKeyFactory` as public field
- Added a couple of fixes and alignments to new architecture

##### TwoKeyFactory
- Added completely new contract which will be in charge to handle deployment of campaigns
- It is upgradable since we'll want in the future this contract to handle all campaign deployments

##### TwoKeyLockupContract - *DELETED*

##### TwoKeyUpgradableExchange
- Implemented stable coin buy logic
- Added 2 new fields:
```
address public kyberProxyContractAddress;
ERC20 public DAI;
```



### Changelog 2key-protocol repository





