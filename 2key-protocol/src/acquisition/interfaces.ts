import {BigNumber} from 'bignumber.js/bignumber';
import {ICreateOpts} from '../interfaces';

export interface IPublicLinkKey {
    contractor: string,
    publicLink: string,
}

export interface ICreateCampaignProgress {
    (contract: string, mined: boolean, transactionResult: string): void;
}

export interface IAcquisitionCampaignMeta {
    contractor: string,
    campaignAddress: string,
    conversionHandlerAddress: string,
    campaignPublicLinkKey: string
}

export interface ITokenAmount {
    baseTokens: number,
    bonusTokens: number,
    totalTokens: number,
}

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
    bonusTokensVestingMonths: number,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: number
}

export interface IPublicMeta {
    private_key: string,
    public_address: string,
}

export interface ILockupInformation {
    'baseTokens' : number,
    'bonusTokens' : number,
    'vestingMonths' : number,
    'conversionId' : number,
    'unlockingDays' : number[],
    'areWithdrawn' : boolean[]
}

export interface ITwoKeyAcquisitionCampaign {
    _getCampaignInstance: (campaign: any) => Promise<any>,
    _getConversionHandlerInstance: (campaign: any) => Promise<any>,
    _getLogicHandlerInstance: (campaign: any) => Promise<any>,
    _getLockupContractInstance: (lockupContract: any) => Promise<any>,
    estimateCreation: (data: IAcquisitionCampaign, from: string) => Promise<number>,
    create: (data: IAcquisitionCampaign, from: string, opts?: ICreateOpts) => Promise<IAcquisitionCampaignMeta>,
    updateOrSetIpfsHashPublicMeta: (campaign: any, hash: string, from: string, gasPrice?: number) => Promise<string>,
    setPrivateMetaHash: (campaign: any, privateMetaHash: string, from:string) => Promise<string>,
    getPrivateMetaHash: (campaign: any, from: string) => Promise<string>,
    getPublicMeta: (campaign: any, from?: string) => Promise<any>,
    checkInventoryBalance: (campaign: any, from: string) => Promise<number | string | BigNumber>,
    getInventoryBalance: (campaign: any, from: string) => Promise<number | string | BigNumber>,
    getPublicLinkKey: (campaign: any, from: string) => Promise<string>,
    getReferrerCut: (campaign: any, from: string) => Promise<number>,
    getAllPendingConverters: (campaign: any, from: string) => Promise<string[]>,
    getApprovedConverters: (campaign: any, from: string) => Promise<string[]>,
    getAllRejectedConverters: (campaign: any, from: string) => Promise<string[]>,
    getConverterConversionIds: (campaign: any, converterAddress: string, from: string) => Promise<number[]>,
    getNumberOfConversions: (campaign:any, from:string) => Promise<number>,
    getConversion: (campaign: any, conversionId: number, from: string) => Promise<IConversionObject>,
    isAddressJoined: (campaign: any, from: string) => Promise<boolean>,
    getBalanceOfArcs: (campaign: any, from: string) => Promise<number>,
    getEstimatedMaximumReferralReward: (campaign: any, from: string, referralLink: string) => Promise<number>,
    setPublicLinkKey: (campaign: any, from: string, publicLink: string, opts?: IPublicLinkOpts) => Promise<IPublicLinkKey>,
    join: (campaign: any, from: string, opts?: IJoinLinkOpts) => Promise<string>,
    joinAndSetPublicLinkWithCut: (campaign: any, from: string, referralLink: string, opts?: IPublicLinkOpts) => Promise<string>,
    joinAndShareARC: (campaign: any, from: string, referralLink: string, recipient: string, opts?: IPublicLinkOpts) => Promise<string>,
    joinAndConvert: (campaign: any, value: string | number | BigNumber, publicLink: string, from: string, opts?: IConvertOpts) => Promise<string>,
    convert: (campaign: any, value: string | number | BigNumber, from: string, opts?: IConvertOpts) => Promise<string>
    convertOffline: (campaign: any, from: string, conversionAmountFiat: number, opts?: IConvertOpts) => Promise<string>
    getEstimatedTokenAmount: (campaign: any, isPaymentFiat: boolean, value: string | number | BigNumber) => Promise<ITokenAmount>,
    getTwoKeyConversionHandlerAddress: (campaign: any) => Promise<string>,
    approveConverter: (campaign: any, converter: string, from: string, gasPrice? :number) => Promise<string>,
    rejectConverter: (campaign: any, converter: string, from: string, gasPrice? :number) => Promise<string>,
    visit: (campaignAddress: string, referralLink: string, from: string) => Promise<string | boolean>,
    executeConversion: (campaign: any, conversion_id: number, from: string, gasPrice? :number) => Promise<string>,
    getLockupContractsForConverter: (campaign: any, converter: string, from: string) => Promise<string[]>,
    addFungibleAssetsToInventoryOfCampaign: (campaign: any, amount: number, from: string, gasPrice? :number) => Promise<string>,
    cancel: (campaign: any, from: string, gasPrice?: number) => Promise<string>,
    isAddressContractor: (campaign:any, from:string) => Promise<boolean>,
    getAmountOfEthAddressSentToAcquisition: (campaign: any, from: string) => Promise<number>,
    contractorWithdraw: (campaign:any, from: string, gasPrice?: number) => Promise<string>,
    getContractorBalance: (campaign:any, from:string) => Promise<number>,
    getModeratorBalance: (campaign:any, from:string) => Promise<number>,
    moderatorAndReferrerWithdraw: (campaign: any, from: string, gasPrice? : number) => Promise<string>,
    getModeratorAddress: (campaign: any, from: string) => Promise<string>,
    getAcquisitionCampaignCurrency: (campaign: any, from: string) => Promise<string>,
    getModeratorTotalEarnings: (campaign:any, from:string) => Promise<number>,
    getReferrerBalanceAndTotalEarningsAndNumberOfConversions: (campaign:any, signature) => Promise<IReferrerSummary>,
    getCurrentAvailableAmountOfTokens: (campaign:any, from:string) => Promise<number>,
    getAddressStatistic: (campaign: any, address: string, plasma?: boolean) => Promise<IAddressStats>,
    getCampaignSummary: (campaign: any, from: string) => Promise<IConversionStats>,
    getLockupContractAddress: (campaign:any, conversionId: number, from:string) => Promise<string>,
    withdrawTokens: (twoKeyLockup: string, part: number, from:string) => Promise<string>,
    changeTokenDistributionDate: (twoKeyLockup: string, newDate: number, from: string) => Promise<string>,
    getLockupInformations: (twoKeyLockup: string, from:string) => Promise<ILockupInformation>,
}

export interface IPublicLinkOpts {
    cut?: number,
    gasPrice?: number,
    progressCallback?: ICreateCampaignProgress,
    interval?: number,
    timeout?: number,
}

export interface IConversionObject {
    'contractor' : string,
    'contractorProceedsETHWei' : number,
    'converter' : string,
    'state' : string,
    'conversionAmount' : number,
    'maxReferralRewardEthWei' : number,
    'moderatorFeeETHWei' : number,
    'baseTokenUnits' : number,
    'bonusTokenUnits' : number,
    'conversionCreatedAt' : number,
    'conversionExpiresAt' : number
    'isConversionFiat' : boolean
}

export interface IConvertOpts {
    gasPrice?: number,
    isConverterAnonymous?: boolean
}

export interface IJoinLinkOpts extends IPublicLinkOpts{
    referralLink?: string,
    cutSign?: string,
    voting?: boolean,
    daoContract?: string,
    progressCallback?: ICreateCampaignProgress,
    interval?: number,
    timeout?: number,
}

export interface IConstantsLogicHandler {
    campaignStartTime: number,
    campaignEndTime: number,
    minContributionETHorFiatCurrency: number,
    maxContributionETHorFiatCurrency: number,
    unit_decimals: number,
    pricePerUnitInETHWeiOrUSD: number,
    maxConverterBonusPercent: number
}

export interface IReferrerSummary {
    balanceAvailable: number,
    totalEarnings: number,
    numberOfConversionsParticipatedIn : number,
    campaignAddress: string,
}

export interface IConversionStats {
    pendingConverters: number,
    approvedConverters: number,
    rejectedConverters: number,
    totalETHRaised: number
}

export interface IAddressStats {
    amountConverterSpentETH: number,
    rewards: number,
    tokensBought: number,
    isConverter: boolean,
    isReferrer: boolean,
    isJoined : boolean,
    username: string,
    fullName: string,
    email: string
    ethereumOf: string,
}