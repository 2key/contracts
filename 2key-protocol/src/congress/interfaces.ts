export interface ITwoKeyCongress {
    getAllowedMethods: (from: string) => Promise<string[]>,
    isUserMemberOfCongress: (member: string, from:string) => Promise<boolean>,
    submitNewProposal: (beneficiary: string, weiAmount: number, jobDescription: string, transactionBytecode: string, from:string) => Promise<number>,
    newProposalInEther: (beneficiary: string, etherAmount: number, jobDescription: string, transactionBytecode: string, from:string) => Promise<number>,
    getAllProposals: (from:string) => Promise<any>,
    vote: (proposalNumber:number, supportsProposal: boolean, justificationText:string, from:string) => Promise<number>,
    executeProposal: (proposalNumber: number, transactionBytecode: string, from: string) => Promise<string>,
    getVoteCount: (proposalNumber: number, from:string) => Promise<any>,
    getMemberInfo: (from: string) => Promise<any>,
    getMethodNameFromHash: (congress: any, hash: string, from:string) => Promise<any>,
    getProposalInformations: (congress: any, proposalId: number, from: string) => Promise<any>,
    getAllMembersForCongress: (congress: any, from:string) => Promise<string[]>,
}
