##1.0.78-develop
####Acquisition
**Change methods**
* _getCampaignInstance: (campaign: any, skipCache?: boolean) => Promise<any>
* getTwoKeyConversionHandlerAddress: (campaign: any, skipCache?: boolean) => Promise<string>
* getLockupContractsForConverter: (campaign: any, converter: string, from: string, skipCache?: boolean) => Promise<string[]>,
* getReferrerBalanceAndTotalEarningsAndNumberOfConversions: (campaign:any, signature, skipCache?: boolean) => Promise<IReferrerSummary>,

##1.0.75-develop
####TwoKeyCampaignValidator -> CampaignValidator
####TwoKeyBaseReputation -> BaseReputation

##1.0.74-develop
####Acquisition
*New methods*
* getNonSingletonsHash: () => Promise<string>,
* _getCampaignInstance: (campaign: any) => Promise<any>,
* _getConversionHandlerInstance: (campaign: any) => Promise<any>,
* _getLogicHandlerInstance: (campaign: any) => Promise<any>,
* _getLockupContractInstance: (lockupContract: any) => Promise<any>,
* withdrawTokens: (twoKeyLockup: string, part: number, from:string) => Promise<string>,
* changeTokenDistributionDate: (twoKeyLockup: string, newDate: number, from: string) => Promise<string>,
* getLockupInformations: (twoKeyLockup: string, from:string) => Promise<ILockupInformation>,

**Changes methods**
* visit: (campaignAddress: string, referralLink: string) => Promise<string | boolean>,
* getReferrerBalanceAndTotalEarningsAndNumberOfConversions: (campaign:any, signature) => Promise<IReferrerSummary>,

####Airdrop
*New methods*
* _getAirdropCampaignInstance: (campaign: any) => Promise<any>,

####CampaignValidator
*New methods*
* validateCampaign: (campaignAddress: string, from:string) => Promise<string>,
* isCampaignValidated: (campaignAddress:string) => Promise<boolean>,
* getCampaignNonSingletonsHash: (campaignAddress:string) => Promise<string>,


####DAO
*New methods*
* _getDecentralizedNationInstance(decentralizedNation: any) : Promise<any>,
* _getWeightedVoteContract: (campaign: any) => Promise<any>,
* createWeightedVoteContract: (data: ITwoKeyWeightedVoteConstructor, from: string, opts?: ICreateOpts) => Promise<string>,


####Lockup
***Removed methods***
* withdrawTokens: (twoKeyLockup: string, part: number, from:string) => Promise<string>,
* changeTokenDistributionDate: (twoKeyLockup: string, newDate: number, from: string) => Promise<string>,
* getLockupInformations: (twoKeyLockup: string, from:string) => Promise<LockupInformation>,

####Plasma
*New methods*
* signReferrerToWithdrawRewards: () => Promise<string>,
* signReferrerToGetRewards: () => Promise<string>,
* getJoinedFrom: (campaignAddress: string, contractorAddress: string, address: string) => Promise<string>,
* getVisitsPerCampaign(campaignAddress: string) => Promise<number>

**Changed methods**
* signPlasmaToEthereum: (from: string, force?: string) => Promise<ISignedEthereum>,

####Registry
**Changed methods**
* signPlasma2Ethereum: (from: string, force?: boolean) => Promise<ISignedPlasma>,
* signUserData2Registry: (from: string, name: string, fullname: string, email: string, force?: boolean) => Promise<ISignedUser>,
* signWalletData2Registry: (from: string, username: string, walletname: string, force?: boolean) => Promise<ISignedWalletData>,

####Reputation
*New methods*
* getReputationPointsForAllRolesPerAddress: (address: string) => Promise<IReputationStatsPerAddress>,

####Utils
*New methods*
* getVersionHandler: () => Promise<boolean>,
* getSubmodule: (nonSingletonHash: string, submoduleName: string) => Promise<string>,

####Helpers
*New methods*
* _awaitPlasmaMethod: (plasmaPromiseMethod: Promise<any>, timeout?: number) => Promise<any>,

***Removed methods***
* _getAcquisitionCampaignInstance: (campaign: any) => Promise<any>,
* _getAcquisitionConversionHandlerInstance: (campaign: any) => Promise<any>
* _getAcquisitionLogicHandlerInstance: (campaign: any) => Promise<any>
* _getAirdropCampaignInstance: (campaign: any) => Promise<any>,
* _getWeightedVoteContract: (campaign: any) => Promise<any>,
* _getDecentralizedNationInstance(decentralizedNation: any) : Promise<any>,
* _getLockupContractInstance(twoKeyLockup: any) : Promise<any>,

**Changed methods**
* _createAndValidate: (abi: any, address: string) => Promise<any>,
* _getNonce: (from: string, pending?: boolean) => Promise<number>,

####VeightedVote
**Removed methods**
* createWeightedVoteContract: (data: ITwoKeyWeightedVoteConstructor, from: string, opts?: ICreateOpts) => Promise<string>,

##1.0.73-develop