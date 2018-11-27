export interface IUpgradableExchange {
    getRate: (from: string) => Promise<number>,
    getERC20Token: (from: string) => Promise<string>,
    getAdmin: (from: string) => Promise<string>,
    getWeiRaised: (from: string) => Promise<number>,

}