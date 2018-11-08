export interface ITwoKeyWeightedVoteContract {
    createWeightedVoteContract: (data: ITwoKeyWeightedVoteConstructor, from: string) => Promise<string>,
}

export interface ITwoKeyWeightedVoteConstructor {
    descriptionForVoting: string,
    addressOfDAO: string
}