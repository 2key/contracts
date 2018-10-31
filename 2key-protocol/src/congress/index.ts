import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {ITwoKeyCongress} from './interfaces';
import {promisify} from '../utils'


export default class TwoKeyCongress implements ITwoKeyCongress {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
    }

    /**
     *
     * @param congress
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getAllowedMethods(congress:any, from: string) : Promise<string[]> {
        return new Promise(async(resolve,reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                let allowedMethods = await promisify(congressInstance.getAllowedMethods, [{from}])
                resolve(allowedMethods);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param congress
     * @param {string} member
     * @param {string} from
     * @returns {Promise<boolean>}
     */
    public isUserMemberOfCongress(congress:any, member: string, from:string) : Promise<boolean> {
        return new Promise(async(resolve, reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                let isUserMember = await promisify(congressInstance.checkIsMember,[member, {from}]);
                resolve(isUserMember);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param congress
     * @param {string} beneficiary
     * @param {number} weiAmount
     * @param {string} jobDescription
     * @param {string} transactionBytecode
     * @param {string} from
     * @returns {Promise<number>}
     */
    public submitNewProposal(congress:any, beneficiary: string, weiAmount: number, jobDescription: string, transactionBytecode: string, from:string) : Promise<number> {
        return new Promise( async(resolve, reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                const nonce = await this.helpers._getNonce(from);
                let proposalId = await promisify(congressInstance.newProposal,[beneficiary,weiAmount,jobDescription,transactionBytecode,{from, nonce}]);
                resolve(proposalId);
            } catch(e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param congress
     * @param {string} beneficiary
     * @param {number} etherAmount
     * @param {string} jobDescription
     * @param {string} transactionBytecode
     * @param {string} from
     * @returns {Promise<number>}
     */
    public newProposalInEther(congress:any, beneficiary: string, etherAmount: number, jobDescription: string, transactionBytecode: string, from:string) : Promise<number> {
        return new Promise( async(resolve, reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                const nonce = await this.helpers._getNonce(from);
                let proposalId = await promisify(congressInstance.newProposal,[beneficiary,etherAmount,jobDescription,transactionBytecode,{from, nonce}]);
                resolve(proposalId);
            } catch(e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param congress
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getAllProposals(congress:any, from:string) : Promise<any> {
        return new Promise(async(resolve,reject) => {
            try {

            } catch(e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param congress
     * @param {number} proposalNumber
     * @param {boolean} supportsProposal
     * @param {string} justificationText
     * @param {string} from
     * @returns {Promise<number>}
     */
    public vote(congress:any, proposalNumber:number, supportsProposal: boolean, justificationText:string, from:string): Promise<number> {
        return new Promise(async(resolve,reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                const nonce = await this.helpers._getNonce(from);
                let voteId = await promisify(congressInstance.vote, [proposalNumber, supportsProposal, justificationText, {from, nonce}]);
                resolve(voteId);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param congress
     * @param {number} proposalNumber
     * @param {string} transactionBytecode
     * @param {string} from
     * @returns {Promise<string>}
     */
    public executeProposal(congress:any, proposalNumber: number, transactionBytecode: string, from: string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                const nonce = await this.helpers._getNonce(from);
                let txHash = await promisify(congressInstance.executeProposal, [proposalNumber,transactionBytecode, {from, nonce}]);
                resolve(txHash);
            } catch(e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param congress
     * @param {number} proposalNumber
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getVoteCount(congress:any, proposalNumber: number, from:string) : Promise<any> {
        return new Promise(async(resolve, reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                let numberOfVotes,
                    currentResult,
                    description;

                [numberOfVotes,currentResult,description] = await promisify(congressInstance.getVoteCount, [{from}]);
                let obj = {
                    numberOfVotes: numberOfVotes,
                    currentResult: currentResult,
                    description: description
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param congress
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getMemberInfo(congress:any, from: string) : Promise<any> {
        return new Promise( async(resolve, reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                let address,
                    name,
                    votingPower,
                    memberSince;

                [address, name, votingPower,memberSince] = await promisify(congressInstance.getMemberInfo, [{from}]);

                let member = {
                    memberAddress: address,
                    memberName: name,
                    memberVotingPower: votingPower,
                    memberSince: memberSince
                };
                resolve(member);
            } catch(e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param congress
     * @param {string} hash
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getMethodNameFromHash(congress: any, hash: string, from: string) : Promise<any> {
        return new Promise( async(resolve,reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                let methodName = await promisify(congressInstance.getMethodNameFromMethodHash, [hash, {from}]);
                resolve(methodName);
            } catch (e) {
                reject(e);
            }
        })
    }

    //p.amount, p.description, p.minExecutionDate, p.executed, p.numberOfVotes, p.currentResult
    public getProposalInformations(congress: any, proposalId: number, from: string) : Promise<any> {
        return new Promise( async(resolve, reject) => {
            try {
                let congressInstance = await this.helpers._getTwoKeyCongressInstance(congress);
                let proposalAmount,
                    proposalDescription,
                    proposalExecutionDate,
                    proposalIsExecuted,
                    proposalNumberOfVotes,
                    proposalCurrentResult,
                    proposalTransactionBytecode;

                [
                    proposalAmount,
                    proposalDescription,
                    proposalExecutionDate,
                    proposalIsExecuted,
                    proposalNumberOfVotes,
                    proposalCurrentResult,
                    proposalTransactionBytecode
                ] = await promisify(congressInstance.getProposalData, [proposalId, {from}]);

                let proposal = {
                    proposalAmount: proposalAmount,
                    proposalDescription: proposalDescription,
                    proposalExecutionDate: proposalExecutionDate,
                    proposalIsExecuted: proposalIsExecuted,
                    proposalNumberOfVotes: proposalNumberOfVotes,
                    proposalCurrentResult: proposalCurrentResult
                };

                resolve(proposal);
            } catch (e) {
                reject(e);
            }
        })
    }
}
