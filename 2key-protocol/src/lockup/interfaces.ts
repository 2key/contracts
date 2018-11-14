export interface ILockup {
    getBaseTokensAmount: (twoKeyLockup: string, from: string) => Promise<number>,
    getBonusTokenAmount: (twoKeyLockup: string, from: string) => Promise<number>,
    checkIfBaseIsUnlocked: (twoKeyLockup: string, from: string) => Promise<number>,
    getMonthlyBonus: (twoKeyLockup: string, from: string) => Promise<number>,
    getAllUnlockedAtTheMoment: (twoKeyLockup: string, from:string) => Promise<number>,
    getAmountUserWithdrawn: (twoKeyLockup: string, from: string) => Promise<number>,
    withdrawTokens: (twoKeyLockup: string, from:string) => Promise<string>,
    getStatistics: (twoKeyLockup: string, from:string) => Promise<any>,
}
