export interface IDecentralizedNation {

}


export interface IDecentralizedNationConstructor {
    nationName: string,
    ipfsHashForConstitution: string,
    ipfsHashForDAOPublicInfo: string,
    initialMemberAddresses: string[],
    initialMemberTypes: string[],
    limitsPerMemberType: number[],
}

