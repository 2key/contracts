export interface IDecentralizedNation {
    createDecentralizedNation: (data: IDecentralizedNationConstructor, from: string) => Promise<string>,
    populateData: (username:string, address:string, fullName:string, email:string, from: string) => Promise<string>
    check: (address: string,from:string) => Promise<boolean>,
    getAllMembersFromDAO: (decentralizedNation:any, from:string) => Promise<any>,
}


export interface IDecentralizedNationConstructor {
    nationName: string,
    ipfsHashForConstitution: string,
    ipfsHashForDAOPublicInfo: string,
    initialMemberAddresses: string[],
    initialMemberTypes: string[],
    limitsPerMemberType: number[],
}

