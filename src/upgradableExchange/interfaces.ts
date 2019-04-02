export interface IUpgradableExchange {
    getRate: (from: string) => Promise<number>,
    getERC20Token: (from: string) => Promise<string>,
    getAdmin: (from: string) => Promise<string>,
    getWeiRaised: (from: string) => Promise<number>,
    getTransactionCount: (from: string) => Promise<number>,
    addContractToBeEligibleToGetTokensFromExchange: (contractAddress: string, from: string) => Promise<string>,
    checkIfContractIsEligibleToBuyTokens: (contractAddress: string) => Promise<boolean>,
}