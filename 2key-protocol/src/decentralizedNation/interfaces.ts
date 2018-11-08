import {ICreateOpts} from '../interfaces';

export interface IDecentralizedNation {
    create: (data: IDecentralizedNationConstructor, from: string, opts?: ICreateOpts) => Promise<string>,
    populateData: (username:string, address:string, fullName:string, email:string, from: string) => Promise<string>
    check: (address: string, from:string) => Promise<boolean>,
    getAllMembersFromDAO: (decentralizedNation:any) => Promise<IMember[]>,
    getAllMembersForSpecificType: (decentralizedNation:any, type:string, from:string) => Promise<any>,
    getVotingPointsForTheMember: (decentralizedNation: any, address: string, from: string) => Promise<number>,
    addMemberByFounder: (decentralizedNation: any, newMemberAddress: string, memberType:string, from:string) => Promise<string>,
    getNameAndIpfsHashesForDAO: (decentralizedNation: any) => Promise<IDaoMeta>,
}

export interface IMember {
    address: string,
    username: string,
    fullname: string,
    email: string,
    type: string,
}

export interface IDaoMeta {
    name: string,
    constitution: string,
    meta: any,
}
/*
bytes32[] eligibleMemberTypes,
        string description,
        address _memberToChangeRole,
        bytes32 _newRole,
        uint _votingCampaignLengthInDays,
        address twoKeyWeightedVoteContract
 */
export interface INationalVotingCampaign {
    eligibleRolesToVote: string[], // bytes32
    votingReason: string, //Just some text
    subjectWeAreVotingFor: string, //The address
    newRoleForTheSubject: string, //bytes32
    campaignLengthInDays: number,
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

