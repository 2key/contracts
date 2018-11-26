export interface ITwoKeyReg {
    checkIfUserIsRegistered: (address: string, from: string) => Promise<boolean>,
    getCampaignsWhereUserIsConverter: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsContractor: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsModerator: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsReferrer: (address: string) => Promise<string[]>,
    getRegistryMaintainers: () => Promise<string[]>,
    setWalletName: (username: string, address: string, username_walletName: string, from: string, gasPrice?: number) => Promise<string>,
}