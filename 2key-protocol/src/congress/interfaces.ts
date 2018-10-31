export interface ITwoKeyCongress {
    getAllowedMethods: (congress:any, from: string) => Promise<string[]>,
    isUserMemberOfCongress: (congress:any, member: string, from:string) => Promise<boolean>,
    submitNewProposal: (congress:any, beneficiary: string, weiAmount: number, jobDescription: string, transactionBytecode: string, from:string) => Promise<number>,
    newProposalInEther: (congress:any, beneficiary: string, etherAmount: number, jobDescription: string, transactionBytecode: string, from:string) => Promise<number>,
    getAllProposals: (congress:any, from:string) => Promise<any>,
    vote: (congress:any, proposalNumber:number, supportsProposal: boolean, justificationText:string, from:string) => Promise<number>,
    executeProposal: (congress:any, proposalNumber: number, transactionBytecode: string, from: string) => Promise<string>,
    getVoteCount: (congress:any, proposalNumber: number, from:string) => Promise<any>,
    getMemberInfo: (congress:any, from: string) => Promise<any>,
    getMethodNameFromHash: (congress: any, hash: string, from:string) => Promise<any>,
    getProposalInformations: (congress: any, proposalId: number, from: string) => Promise<any>,
}
