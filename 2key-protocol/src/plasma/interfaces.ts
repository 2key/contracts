export interface IPlasmaEvents {
    getRegisteredAddressForPlasma: (plasma?: string) => Promise<string>,
    signReferrerForWithrawRewards: () => Promise<string>,
    signPlasmaToEthereum: (from: string) => Promise<ISignedEthereum>,
    setPlasmaToEthereumOnPlasma: (plasmaAddress: string, plasma2EthereumSignature: string) => Promise<string>,
    getVisitsList: (campaignAddress: string, contractorAddress: string, address: string) => Promise<IVisits>,
    getVisitedFrom: (campaignAddress: string, contractorAddress: string, address: string) => Promise<string>,
    getJoinedFrom: (campaignAddress: string, contractorAddress: string, address: string) => Promise<string>,
}

export interface ISignedEthereum {
    plasmaAddress: string,
    plasma2ethereumSignature: string,
}

export interface IVisits {
    visits: string[],
    timestamps: number[],
}