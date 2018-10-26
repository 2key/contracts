import {BigNumber} from 'bignumber.js';
import {
    ICreateCampaignProgress,
} from '../interfaces';

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
    estimateCreation: (params: IEstimateCreation) => Promise<number>,
    create: (params: ICreate) => Promise<IAcquisitionCampaignMeta>,
    updateOrSetIpfsHashPublicMeta: (params: IUpdateOrSetIpfsHashPublicMeta) => Promise<string>,
    getPublicMeta: (params: IGetPublicMeta) => Promise<any>,

    checkInventoryBalance: (params: ICampaignData) => Promise<number | string | BigNumber>,
    getInventoryBalance: (params: ICampaignData) => Promise<number | string | BigNumber>,
    getPublicLinkKey: (params: ICampaignData) => Promise<string>,
    getReferrerCut: (params: ICampaignData) => Promise<number>,
    getConverterConversion: (params: ICampaignData) => Promise<any>,
    getAllPendingConverters: (params: ICampaignData) => Promise<string[]>,
    cancelConverter: (params: ICampaignData) => Promise<string>,
    getApprovedConverters: (params: ICampaignData) => Promise<string[]>,
    getAllRejectedConverters: (params: ICampaignData) => Promise<string[]>,
    isAddressJoined: (params: ICampaignData) => Promise<boolean>,
    getBalanceOfArcs: (params: ICampaignData) => Promise<number>,

    setPublicLinkKey: (params: IJoinLink) => Promise<IPublicLinkKey>,
    getEstimatedMaximumReferralReward: (params: ICampaignData) => Promise<number>,
    join: (params: IJoinLink) => Promise<string>,
    joinAndSetPublicLinkWithCut: (params: IJoinLink) => Promise<string>,
    joinAndShareARC: (params: IShareARC) => Promise<string>,
    joinAndConvert: (campaign: any, value: string | number | BigNumber, publicLink: string, from: string, gasPrice?: number) => Promise<string>,
    getTwoKeyConversionHandlerAddress: (campaign: any) => Promise<string>,
    // getAssetContractData: (campaign: any) => Promise<any>,
    approveConverter: (campaign: any, converter: string, from: string) => Promise<string>,
    rejectConverter: (campaign: any, converter: string, from: string) => Promise<string>,
    visit: (campaignAddress: string, referralLink: string) => Promise<string>,
    executeConversion: (campaign: any, converter: string, from: string) => Promise<string>,
    getLockupContractsForConverter: (campaign: any, converter: string, from: string) => Promise<string[]>,
    addFungibleAssetsToInventoryOfCampaign(campaign: any, amount: number, from: string) : Promise<string>,
}

export interface IJoinLink {
    campaign: any,
    publicLink: string | null,
    from: string,
    cut?: number,
    gasPrice?: number,
}

export interface IShareARC extends IJoinLink {
    recipient: string,
}

export interface IJoinAndConvert extends IJoinLink {
    value: number | string | BigNumber,
}

export interface IEstimateCreation {
    data: IAcquisitionCampaign,
    from: string,
}

export interface ICreate {
    data: IAcquisitionCampaign,
    from: string,
    progressCallback?: ICreateCampaignProgress,
    gasPrice?: number,
    interval?: number,
    timeout?: number
}

export interface IUpdateOrSetIpfsHashPublicMeta {
    campaign: any,
    hash: string,
    from: string,
    gasPrice?: number,
}

export interface IGetPublicMeta {
    campaign: any,
    from?: string,
}

export interface ICampaignData {
    campaign: any,
    from: string,
    referralLink?: string,
}
