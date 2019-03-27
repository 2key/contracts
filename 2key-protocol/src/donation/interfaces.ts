import {ICreateCampaignProgress} from "../interfaces";
import {IConvertOpts} from "../acquisition/interfaces";
import {BigNumber} from "bignumber.js";

export interface IDonationCampaign {
    create: (data: ICreateCampaign, from: string, opts?: ICreateOpts) => Promise<any>,
    getIncentiveModel: (campaignAddress: string) => Promise<string>,
    visit: (campaignAddress: string, referralLink: string)=> Promise<string>,
    updateOrSetIpfsHashPublicMeta: (campaign: any, hash: string, from: string, gasPrice?: number) => Promise<string>,
    joinAndConvert: (campaign: any, value: string | number | BigNumber, publicLink: string, from: string, opts?: IConvertOpts) => Promise<string>,
    approveConverter: (campaignAddress: string, converter: string, from:string) => Promise<string>,
    getDonation: (campaignAddress: string, donationId: number, from: string) => Promise<IDonation>,
    getPublicLinkKey: (campaign: any, from: string) => Promise<string>,
    getPublicMeta: (campaign: any, from?: string) => Promise<any>,
    getPrivateMetaHash: (campaign: any, from: string) => Promise<string>,
    setPrivateMetaHash: (campaign: any, data: any, from:string) => Promise<string>,
    getRefferrersToConverter: (campaignAddress: string, converter: string, from: string) => Promise<string[]>,
}

/**
 * Interface to describe necessary params in order to create Donation Campaign
 */
export interface ICreateCampaign {
    moderator: string,
    campaignName: string,
    invoiceToken: InvoiceERC20,
    maxReferralRewardPercent: number,
    campaignStartTime: number,
    campaignEndTime: number,
    minDonationAmount: number,
    maxDonationAmount: number,
    campaignGoal: number,
    conversionQuota: number,
    shouldConvertToRefer: boolean,
    isKYCRequired: boolean,
    incentiveModel: number
}

/**
 * Interface to describe token which will be deployed with campaign
 * Will be used as an invoice token for donations so people can proof their donations
 */
export interface InvoiceERC20 {
    tokenName: string,
    tokenSymbol: string
}

export interface IDonation {
    donator: string,
    donationAmount: number,
    contractorProceeds: number,
    donationTime: number,
    bountyEthWei: number,
    bounty2key: number,
    state: string
}

export interface ICampaignData {
    campaignStartTime: number,
    campaignEndTime: number,
    minDonationAmountWei: number,
    maxDonationAmountWei: number,
    maxReferralRewardPercent: number,
    publicMetaHash: string,
    shouldConvertToRefer: boolean,
    campaignName: string
}


export interface IConvertOpts {
    gasPrice?: number,
    isConverterAnonymous?: boolean
}

/**
 * Optional params
 */
export interface ICreateOpts {
    progressCallback?: ICreateCampaignProgress,
    gasPrice?: number,
    interval?: number,
    timeout?: number
}
