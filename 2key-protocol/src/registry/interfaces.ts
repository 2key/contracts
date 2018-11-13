export interface ITwoKeyReg {
    getCampaignsWhereConverter: (from: string) => Promise<string[]>,
    checkIfUserIsRegistered: (address: string, from: string) => Promise<boolean>,
}