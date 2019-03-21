import {ICreateCampaignProgress} from "../interfaces";

export interface IDonationCampaign {
    create: (data: ICreateCampaign, from: string, opts?: ICreateOpts) => Promise<string>,
    updateOrSetIpfsHashPublicMeta: (campaign: any, hash: string, from: string, gasPrice?: number) => Promise<string>,
    getPublicMeta: (campaign: any, from?: string) => Promise<any>,
    getDonation: (campaignAddress: string, donationId: number, from: string) => Promise<IDonation>,
    getPublicLinkKey: (campaign: any, from: string) => Promise<string>,
    visit: (campaignAddress: string, referralLink: string)=> Promise<string>,
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
    donationAmount: number
    donationTime: number,
    bountyEthWei: number,
    bounty2key: number
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

/**
 * Optional params
 */
export interface ICreateOpts {
    progressCallback?: ICreateCampaignProgress,
    gasPrice?: number,
    interval?: number,
    timeout?: number
}
