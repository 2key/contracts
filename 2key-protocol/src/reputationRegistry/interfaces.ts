export interface ITwoKeyBaseReputationRegistry {
    getReputationPointsForAllRolesPerAddress: (address: string) => Promise<IReputationStatsPerAddress>,
}

export interface IReputationStatsPerAddress {
    reputationPointsAsContractor: number
    reputationPointsAsConverter: number,
    reputationPointsAsReferrer: number
}