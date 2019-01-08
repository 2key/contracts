export interface ITwoKeyCongress {
    getAllowedMethods: (from: string) => Promise<string[]>,
    isUserMemberOfCongress: (member: string, from:string) => Promise<boolean>,
    newProposalInWei: (beneficiary: string, weiAmount: number, jobDescription: string, transactionBytecode: string, from:string) => Promise<number>,
    newProposalInEther: (beneficiary: string, etherAmount: number, jobDescription: string, transactionBytecode: string, from:string) => Promise<number>,
    getAllProposals: (from:string) => Promise<any>,
    vote: (proposalNumber:number, supportsProposal: boolean, justificationText:string, from:string) => Promise<number>,
    executeProposal: (proposalNumber: number, transactionBytecode: string, from: string) => Promise<string>,
    getVoteCount: (proposalNumber: number, from:string) => Promise<any>,
    getMemberInfo: (from: string) => Promise<IMemberInfo>,
    getMethodNameFromHash: (hash: string, from:string) => Promise<string>,
    getProposalInformations: (proposalId: number, from: string) => Promise<any>,
    getAllMembersForCongress: (from:string) => Promise<string[]>,
}

export interface IMemberInfo {
    memberAddress: string,
    memberName: string,
    memberVotingPower: number,
    memberSince: number
}
