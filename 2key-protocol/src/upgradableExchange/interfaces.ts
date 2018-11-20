export interface IUpgradableExchange {
    getRate: (upgradableExchange: any, from: string) => Promise<number>,
}