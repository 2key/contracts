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
                let proposalId = await promisify(congressInstance.newProposal,[beneficiary,weiAmount,jobDescription,transactionBytecode,{from}]);
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
                let voteId = await promisify(congressInstance.vote, [proposalNumber, supportsProposal, justificationText, {from}]);
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
                let txHash = await promisify(congressInstance.executeProposal, [proposalNumber,transactionBytecode, {from}]);
                resolve(txHash);
            } catch(e) {
                reject(e);
            }
        })
    }






}