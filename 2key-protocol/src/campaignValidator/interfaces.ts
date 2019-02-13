export interface ITwoKeyCampaignValidator {
    validateCampaign: (campaignAddress: string, from:string) => Promise<string>,
}