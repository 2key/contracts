export interface ITwoKeyCampaignValidator {
    validateCampaign: (campaignAddress: string, from:string) => Promise<string>,
    isCampaignValidated: (campaignAddress:string) => Promise<boolean>,
}