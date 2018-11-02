export interface ILockup {
    getCampaignsWhereConverter:(from: string) => Promise<string[]>,
}
