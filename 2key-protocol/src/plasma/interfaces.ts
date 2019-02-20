export interface IPlasmaEvents {
    getRegisteredAddressForPlasma: (plasma?: string) => Promise<string>,
    signReferrerToWithdrawRewards: () => Promise<string>,
    signReferrerToGetRewards: () => Promise<string>,
    signPlasmaToEthereum: (from: string, force?: string) => Promise<ISignedEthereum>,
    setPlasmaToEthereumOnPlasma: (plasmaAddress: string, plasma2EthereumSignature: string) => Promise<string>,
    getVisitsList: (campaignAddress: string, contractorAddress: string, address: string) => Promise<IVisits>,
    getVisitedFrom: (campaignAddress: string, contractorAddress: string, address: string) => Promise<string>,
    getJoinedFrom: (campaignAddress: string, contractorAddress: string, address: string) => Promise<string>,
    getVisitsPerCampaign: (campaignAddress: string) => Promise<number>,
    getNumberOfVisitsAndJoins: (campaignAddress: string) => Promise<IVisitsAndJoins>,
}

export interface ISignedEthereum {
    plasmaAddress: string,
    plasma2ethereumSignature: string,
}

export interface IVisits {
    visits: string[],
    timestamps: number[],
}

export interface IVisitsAndJoins {
    visits: number
    joins: number,
}