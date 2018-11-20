export interface IUpgradableExchange {
    getRate: (upgradableExchange: any, from: string) => Promise<number>,
    getERC20Token: (upgradableExchange: any, from: string) => Promise<string>,
}