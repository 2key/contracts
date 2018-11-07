export interface IDecentralizedNation {

}

export interface IDecentralizedNationConstructor {
    nationName: string,
    ipfsHashForConstitution: string,
    ipfsHashForDAOPublicInfo: string,
    initialMemberAddresses: string[],
    initialMemberTypes: string[],
    twoKeyRegistry: string,

}

/*
string _nationName,
        bytes32 _ipfsHashForConstitution,
        bytes32 _ipfsHashForDAOPublicInfo,
        address[] initialMembersAddresses,
        bytes32[] initialMemberTypes,
        address _twoKeyRegistry
 */