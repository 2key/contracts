export interface ITwoKeyReg {
    checkIfAddressIsRegistered: (address: string) => Promise<boolean>,
    checkIfUserIsRegistered: (username: string) => Promise<string>,
    getCampaignsWhereUserIsConverter: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsContractor: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsModerator: (address: string) => Promise<string[]>,
    getCampaignsWhereUserIsReferrer: (address: string) => Promise<string[]>,
    addName: (username:string, sender: string, fullName:string, email:string, signature: string, from: string) => Promise<string>,
    getUserData: (address: string) => Promise<IUserData>,
    setWalletName(from: string, signedWallet: ISignedWalletData, gasPrice?: number): Promise<string>
    signPlasma2Ethereum: (from: string) => Promise<ISignedPlasma>,
    signUserData2Registry: (from: string, name: string, fullname: string, email: string) => Promise<ISignedUser>,
    signWalletData2Registry: (from: string, username: string, walletname: string) => Promise<ISignedWalletData>,
    addPlasma2EthereumByUser: (from: string, signedPlasma: ISignedPlasma) => Promise<string>,
    addNameAndWalletName: (from: string, userName: string, userAddress: string, fullName: string, email: string, walletName: string, signedUserData: string, signedWalletData: string, gasPrice?: number) => Promise<string>,
}

export interface IUserData {
    username: string,
    fullname: string,
    email: string,
}

export interface ISignedUser {
    name: string,
    address: string,
    fullname: string,
    email: string,
    signature: string,
}
export interface ISignedWalletData {
    username: string,
    address: string,
    walletname: string,
    signature: string,
}

export interface ISignedPlasma {
    encryptedPlasmaPrivateKey: string,
    ethereum2plasmaSignature: string,
    externalSignature: string
}