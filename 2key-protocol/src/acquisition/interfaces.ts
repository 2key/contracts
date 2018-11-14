import {BigNumber} from 'bignumber.js';
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
    moderator?: string, // Address of the moderator - it's a contract that works (operates) as admin of whitelists contracts
    conversionHandlerAddress?: string,
    assetContractERC20: string,
    campaignStartTime: number, // Timestamp
    campaignEndTime: number, // Timestamp
    expiryConversion: number, // Timestamp
    moderatorFeePercentageWei: number | string | BigNumber,
    maxReferralRewardPercentWei: number | string | BigNumber,
    maxConverterBonusPercentWei: number | string | BigNumber,
    pricePerUnitInETHWei: number | string | BigNumber,
    minContributionETHWei: number | string | BigNumber,
    maxContributionETHWei: number | string | BigNumber,
    referrerQuota?: number,
    tokenDistributionDate: number,
    maxDistributionDateShiftInDays: number,
    bonusTokensVestingMonths: number,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: number
}


export interface ITwoKeyAcquisitionCampaign {
    estimateCreation: (data: IAcquisitionCampaign, from: string) => Promise<number>,
    create: (data: IAcquisitionCampaign, from: string, opts?: ICreateOpts) => Promise<IAcquisitionCampaignMeta>,
    updateOrSetIpfsHashPublicMeta: (campaign: any, hash: string, from: string, gasPrice?: number) => Promise<string>,

    getPublicMeta: (campaign: any, from?: string) => Promise<any>,
    checkInventoryBalance: (campaign: any, from: string) => Promise<number | string | BigNumber>,
    getInventoryBalance: (campaign: any, from: string) => Promise<number | string | BigNumber>,
    getPublicLinkKey: (campaign: any, from: string) => Promise<string>,
    getReferrerCut: (campaign: any, from: string) => Promise<number>,
    getConverterConversion: (campaign: any, from: string) => Promise<any>,
    getAllPendingConverters: (campaign: any, from: string) => Promise<string[]>,
    cancelConverter: (campaign: any, from: string) => Promise<string>,
    getApprovedConverters: (campaign: any, from: string) => Promise<string[]>,
    getAllRejectedConverters: (campaign: any, from: string) => Promise<string[]>,
    isAddressJoined: (campaign: any, from: string) => Promise<boolean>,
    getBalanceOfArcs: (campaign: any, from: string) => Promise<number>,

    getEstimatedMaximumReferralReward: (campaign: any, from: string, referralLink: string) => Promise<number>,
    setPublicLinkKey: (campaign: any, from: string, publicLink: string, opts?: IPublicLinkOpts) => Promise<IPublicLinkKey>,
    join: (campaign: any, from: string, opts?: IJoinLinkOpts) => Promise<string>,
    joinAndSetPublicLinkWithCut: (campaign: any, from: string, referralLink: string, opts?: IPublicLinkOpts) => Promise<string>,
    joinAndShareARC: (campaign: any, from: string, referralLink: string, recipient: string, opts?: IPublicLinkOpts) => Promise<string>,
    joinAndConvert: (campaign: any, value: string | number | BigNumber, publicLink: string, from: string, gasPrice?: number) => Promise<string>,
    getEstimatedTokenAmount: (campaign: any, value: string | number | BigNumber) => Promise<ITokenAmount>,
    getTwoKeyConversionHandlerAddress: (campaign: any) => Promise<string>,
    // getAssetContractData: (campaign: any) => Promise<any>,
    approveConverter: (campaign: any, converter: string, from: string, gasPrice? :number) => Promise<string>,
    rejectConverter: (campaign: any, converter: string, from: string, gasPrice? :number) => Promise<string>,
    visit: (campaignAddress: string, referralLink: string) => Promise<string>,
    executeConversion: (campaign: any, converter: string, from: string, gasPrice? :number) => Promise<string>,
    getLockupContractsForConverter: (campaign: any, converter: string, from: string) => Promise<string[]>,
    addFungibleAssetsToInventoryOfCampaign: (campaign: any, amount: number, from: string, gasPrice? :number) => Promise<string>,
    cancel: (campaign: any, from: string, gasPrice?: number) => Promise<string>,
    isAddressContractor: (campaign:any, from:string) => Promise<boolean>,
    getAcquisitionContractBalanceERC20: (campaign: any) => Promise<number>,
    getAmountOfEthAddressSentToAcquisition: (campaign: any, from: string) => Promise<number>,
    contractorWithdraw: (campaign:any, from: string, gasPrice?: number) => Promise<string>,
    getContractorBalance: (campaign:any, from:string) => Promise<number>,
    getModeratorBalance: (campaign:any, from:string) => Promise<number>,
}

export interface IPublicLinkOpts {
    cut?: number,
    gasPrice?: number,
}

export interface IJoinLinkOpts extends IPublicLinkOpts{
    referralLink?: string,
    cutSign?: string,
    voting?: boolean,
    daoContract?: string,
}
