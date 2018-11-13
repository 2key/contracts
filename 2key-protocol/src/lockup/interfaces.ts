export interface ILockup {
    getBaseTokensAmount: (twoKeyLockup: string, from: string) => Promise<number>,
    getBonusTokenAmount: (twoKeyLockup: string, from: string) => Promise<number>,

}
