export interface IDecentralizedNation {
    createDecentralizedNation: (data: IDecentralizedNationConstructor, from: string) => Promise<string>,
    populateData: (username:string, address:string, fullName:string, email:string, from: string) => Promise<string>
    check: (address: string,from:string) => Promise<boolean>,
    getAllMembersFromDAO: (decentralizedNation:any, from:string) => Promise<any>,
    getAllMembersForSpecificType: (decentralizedNation:any, type:string, from:string) => Promise<any>,
    getVotingPointsForTheMember: (decentralizedNation: any, address: string, from: string) => Promise<number>,
    addMemberByFounder: (decentralizedNation: any, newMemberAddress: string, memberType:string, from:string) => Promise<string>,
}


export interface IDecentralizedNationConstructor {
    nationName: string,
    ipfsHashForConstitution: string,
    ipfsHashForDAOPublicInfo: string,
    initialMemberAddresses: string[],
    initialMemberTypes: string[],
    limitsPerMemberType: number[],
    eligibleToStartVotingCampaign: number[],
    minimalNumberOfVotersForVotingCampaign: number,
    minimalPercentOfVotersForVotingCampaign: number,
    minimalNumberOfVotersForPetitioningCampaign: number,
    minimalPercentOfVotersForPetitioningCampaign: number,
}

