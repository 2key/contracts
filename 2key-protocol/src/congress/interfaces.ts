export interface ITwoKeyCongress {
    getAllowedMethods: (from: string) => Promise<string[]>,
    isUserMemberOfCongress: (member: string, from:string) => Promise<boolean>,
    newProposal: (beneficiary: string,jobDescription: string, transactionBytecode: string, from:string) => Promise<string>,
    newProposalInEther: (beneficiary: string, etherAmount: number, jobDescription: string, transactionBytecode: string, from:string) => Promise<number>,
    getAllProposals: (from:string) => Promise<any>,
    vote: (proposalNumber:number, supportsProposal: boolean, justificationText:string, from:string) => Promise<string>,
    executeProposal: (proposalNumber: number, transactionBytecode: string, from: string) => Promise<string>,
    getVoteCount: (proposalNumber: number, from:string) => Promise<any>,
    getMemberInfo: (from: string) => Promise<IMemberInfo>,
    getMethodNameFromHash: (hash: string, from:string) => Promise<string>,
    getProposalInformations: (proposalId: number, from: string) => Promise<any>,
    getAllMembersForCongress: (from:string) => Promise<string[]>,
    getNumberOfProposals: () => Promise<number>,
}

export interface IMemberInfo {
    memberAddress: string,
    memberName: string,
    memberVotingPower: number,
    memberSince: number
}
