export interface IDonationCampaign {

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
    campaignStartTime: number,
    campaignEndTime: number,
    minDonationAmount: number,
    maxDonationAmount: number,
    campaignGoal: number,
    conversionQuota: number,
    singletoneRegistry: string,
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
