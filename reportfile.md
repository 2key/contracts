## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| TwoKeyAcquisitionCampaignERC20.sol | 662fb89520de4c3cd6f6f9876e81311863b36890 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **TwoKeyAcquisitionCampaignERC20** | Implementation | TwoKeyCampaignARC |||
| └ | \<Constructor\> | Public ❗️ | 🛑  | TwoKeyCampaignARC |
| └ | setERC20Attributes | Internal 🔒 | 🛑  | |
| └ | calculateModeratorFee | Internal 🔒 |   | |
| └ | addUnitsToInventory | Public ❗️ | 🛑  | |
| └ | setPublicLinkKey | Public ❗️ | 🛑  | |
| └ | setCut | Public ❗️ | 🛑  | |
| └ | distributeArcsBasedOnSignature | Public ❗️ | 🛑  | |
| └ | joinAndShareARC | Public ❗️ | 🛑  | |
| └ | requirementForMsgValue | Internal 🔒 | 🛑  | |
| └ | joinAndConvert | Public ❗️ |  💵 | |
| └ | convert | Public ❗️ |  💵 | |
| └ | \<Fallback\> | External ❗️ |  💵 | |
| └ | createConversion | Internal 🔒 | 🛑  | |
| └ | updateRefchainRewards | Public ❗️ | 🛑  | onlyTwoKeyConversionHandler |
| └ | moveFungibleAsset | Public ❗️ | 🛑  | onlyTwoKeyConversionHandler |
| └ | getAmountAddressSent | Public ❗️ |   | |
| └ | getConstantInfo | Public ❗️ |   | |
| └ | getReferrerCuts | Public ❗️ |   | |
| └ | getReferrerCut | Public ❗️ |   | |
| └ | getInventoryBalance | Internal 🔒 |   | |
| └ | getEstimatedTokenAmount | Public ❗️ |   | |
| └ | setPrivateMetaHash | Public ❗️ | 🛑  | onlyContractor |
| └ | getPrivateMetaHash | Public ❗️ |   | onlyContractor |
| └ | updateMinContributionETHOrUSD | Public ❗️ | 🛑  | onlyContractor |
| └ | updateMaxContributionETHorUSD | Public ❗️ | 🛑  | onlyContractor |
| └ | updateMaxReferralRewardPercent | Public ❗️ | 🛑  | onlyContractor |
| └ | updateOrSetIpfsHashPublicMeta | Public ❗️ | 🛑  | onlyContractor |
| └ | updateModeratorBalanceETHWei | Public ❗️ | 🛑  | onlyTwoKeyConversionHandler |
| └ | updateContractorProceeds | Public ❗️ | 🛑  | onlyTwoKeyConversionHandler |
| └ | getAddressJoinedStatus | Public ❗️ |   | |
| └ | sendBackEthWhenConversionCancelled | Public ❗️ | 🛑  | onlyTwoKeyConversionHandler |
| └ | getContractorBalance | Public ❗️ |   | onlyContractor |
| └ | getModeratorBalanceAndTotalEarnings | Public ❗️ |   | onlyContractorOrModerator |
| └ | getReferrerBalanceAndTotalEarningsAndNumberOfConversions | Public ❗️ |   | |
| └ | withdrawContractor | Public ❗️ | 🛑  | onlyContractor |
| └ | withdrawModeratorOrReferrer | Public ❗️ | 🛑  | |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
