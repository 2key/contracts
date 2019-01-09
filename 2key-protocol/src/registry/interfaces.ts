export interface ITwoKeyReg {
    checkIfAddressIsRegistered: (address: string) => Promise<boolean>,
    checkIfUserIsRegistered: (username: string) => Promise<string>,
    getCampaignsWhereUserIsConverter: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsContractor: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsModerator: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsReferrer: (address: string) => Promise<string[]>,
    addName: (username:string, address:string, fullName:string, email:string, from: string) => Promise<string>,
    getUserData: (address: string) => Promise<IUserData>,
    setWalletName: (username: string, address: string, username_walletName: string, from: string, gasPrice?: number) => Promise<string>,
}

export interface IUserData {
    username: string,
    fullname: string,
    email: string,
}