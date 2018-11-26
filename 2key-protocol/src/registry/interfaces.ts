export interface ITwoKeyReg {
    checkIfUserIsRegistered: (address: string, from: string) => Promise<boolean>,
    getCampaignsWhereUserIsConverter: (from: string) => Promise<string[]>,
    getCampaignsWhereUserIsContractor: (from: string) => Promise<string[]>,
    getCampaignsWhereUserIsModerator: (from: string) => Promise<string[]>,
    getCampaignsWhereUserIsReferrer: (from: string) => Promise<string[]>,
}