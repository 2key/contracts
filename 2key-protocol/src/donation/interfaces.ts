import {ICreateCampaignProgress} from "../interfaces";

export interface IDonationCampaign {
    create: (data: ICreateCampaign, from: string, opts?: ICreateOpts) => Promise<string>,
    getContractData: (campaignAddress: string) => Promise<ICampaignData>,
    getPublicLinkKey: (campaign: any, from: string) => Promise<string>
}

/**
 * Interface to describe necessary params in order to create Donation Campaign
 */
export interface ICreateCampaign {
    moderator: string,
    campaignName: string,
    publicMetaHash: string,
    privateMetaHash: string,
    invoiceToken: InvoiceERC20,
    maxReferralRewardPercent: number,
    campaignStartTime: number,
    campaignEndTime: number,
    minDonationAmount: number,
    maxDonationAmount: number,
    campaignGoal: number,
    conversionQuota: number,
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

export interface ICampaignData {
    campaignStartTime: number,
    campaignEndTime: number,
    minDonationAmount: number,
    maxDonationAmount: number,
    maxReferralRewardPercent: number,
    campaignName: string
    publicMetaHash: string
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
