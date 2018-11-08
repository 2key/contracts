import {ICreateOpts} from "../interfaces";

export interface ITwoKeyWeightedVoteContract {
    createWeightedVoteContract: (data: ITwoKeyWeightedVoteConstructor, from: string, opts?: ICreateOpts) => Promise<string>,
}

export interface ITwoKeyWeightedVoteConstructor {
    descriptionForVoting: string,
    addressOfDAO: string
}