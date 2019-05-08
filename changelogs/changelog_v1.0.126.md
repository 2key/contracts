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

##### acquisition/index.ts

- Constructor of Acquisition changed
```
constructor(
        twoKeyProtocol: ITwoKeyBase,
        helpers: ITwoKeyHelpers,
        utils: ITwoKeyUtils,
        erc20: IERC20,
        sign: ISign,
        twoKeyFactory: ITwoKeyFactory,
        upgradableExchange: IUpgradableExchange,
    ) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
        this.erc20 = erc20;
        this.sign = sign;
        this.twoKeyFactory = twoKeyFactory;
        this.nonSingletonsHash = acquisitionContracts.NonSingletonsHash;
        this.upgradableExchange = upgradableExchange;
        // console.log('ACQUISITION', this.nonSingletonsHash, this.nonSingletonsHash.length);
    }
```

- Added `_getPurchasesHandlerInstance` method
- Expanded with `twoKeyPurchasesHandler`
```
let extraMetaInfo = {
                    'contractor' : from,
                    'web3_address' : campaignAddress,
                    conversionHandlerAddress,
                    twoKeyAcquisitionLogicHandlerAddress,
                    twoKeyPurchasesHandler,
                    ephemeralContractsVersion: this.nonSingletonsHash,
                };
```
- Modified `getConversion` method doesn't return anymore lockup address
- Added `getPurchaseInformation` method resolves `IPurchaseInformation`
- Added `getBoughtTokensReleaseDates` method 
- Modified `public withdrawTokens(campaign: any, conversionId: number, portion: number, from:string) : Promise<string>`
- Added `getRequiredRewardsInventoryAmount(acceptsFiat: boolean, acceptsEther: boolean, hardCap: number, maxReferralRewardPercent: number) : Promise<number>`
- Added `public isEnoughRewardsForFiatParticipation(campaign: any, fiatWei: number) : Promise<IPossibleFiatReward>`
- Modified `IAcquisitionCampaignMeta`
```
export interface IAcquisitionCampaignMeta {
    contractor: string,
    campaignAddress: string,
    conversionHandlerAddress: string,
    twoKeyAcquisitionLogicHandlerAddress: string,
    twoKeyPurchasesHandler: string,
    campaignPublicLinkKey: string
    ephemeralContractsVersion: string,
    publicMetaHash: string,
    privateMetaHash: string,
}
```
- Modified `IAcquisitionCampaign` with 2 added params to the bottom
```
export interface IAcquisitionCampaign {
    generatePublicMeta: () => IPublicMeta,
    moderator?: string, // Address of the moderator - it's a contract that works (operates) as admin of whitelists contracts
    conversionHandlerAddress?: string,
    twoKeyAcquisitionLogicHandler?: string,
    assetContractERC20: string,
    campaignStartTime: number, // Timestamp
    campaignEndTime: number, // Timestamp
    expiryConversion: number, // Timestamp
    maxReferralRewardPercentWei: number | string | BigNumber,
    maxConverterBonusPercentWei: number | string | BigNumber,
    pricePerUnitInETHWei: number | string | BigNumber,
    minContributionETHWei: number | string | BigNumber,
    maxContributionETHWei: number | string | BigNumber,
    referrerQuota?: number,
    currency: string,
    twoKeyExchangeContract: string,
    tokenDistributionDate: number,
    maxDistributionDateShiftInDays: number,
    numberOfVestingPortions: number,
    numberOfDaysBetweenPortions: number,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: number,
    isKYCRequired: boolean,
    isFiatConversionAutomaticallyApproved: boolean,
    incentiveModel: string,
    isFiatOnly: boolean,
    vestingAmount: string,
    mustConvertToReferr: boolean
}
```

- Added interface IPurchaseInformation
```
{
    converter: string,
    baseTokens: number,
    bonusTokens: number,
    portionAmount: number[],
    isPortionWithdrawn: boolean[],
    unlockingDays: number[]
}
```

##### Other protocol changes
There are a couple of more changes and fixes such as: 
- Deployment goes through TwoKeyFactory not through SingletonRegistry anymore
- sign/index.ts -> When joining extra cut validation
- Switched IPFS to our 2key nodes
