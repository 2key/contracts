import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {IDecentralizedNation, IDecentralizedNationConstructor, IMember} from "./interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {promisify} from "../utils";
import contracts from '../contracts';

export default class DecentralizedNation implements IDecentralizedNation {
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
     * @param {IDecentralizedNationConstructor} data
     * @param {string} from
     * @returns {Promise<string>}
     */
    public check(address: string, from:string): Promise<boolean> {
        return new Promise(async(resolve,reject) => {
            try {
                let exists = await promisify(this.base.twoKeyReg.checkIfTwoKeyMaintainerExists, [address, {from}]);
                resolve(exists);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} username
     * @param {string} address
     * @param {string} fullName
     * @param {string} email
     * @param {string} from
     * @returns {Promise<string>}
     */
    public populateData(username:string, address:string, fullName:string, email:string, from: string): Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                 const nonce = await this.helpers._getNonce(from);
                 let txHash = await promisify(this.base.twoKeyReg.addName,[
                        username,
                        address,
                        fullName,
                        email,
                        {
                            from,
                            nonce
                        }
                    ]);
                    await this.utils.getTransactionReceiptMined(txHash);
                resolve(txHash);
            } catch(e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {IDecentralizedNationConstructor} data
     * @param {string} from
     * @returns {Promise<string>}
     */
    public createDecentralizedNation(data: IDecentralizedNationConstructor, from: string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                const txHash = await this.helpers._createContract(contracts.DecentralizedNation ,from, {params: [
                    data.nationName,
                    data.ipfsHashForConstitution,
                    data.ipfsHashForDAOPublicInfo,
                    data.initialMemberAddresses,
                    data.initialMemberTypes.map(type => this.base.web3.toHex(type)),
                    data.limitsPerMemberType,
                    data.eligibleToStartVotingCampaign,
                    data.minimalNumberOfVotersForVotingCampaign,
                    data.minimalPercentOfVotersForVotingCampaign,
                    data.minimalNumberOfVotersForPetitioningCampaign,
                    data.minimalPercentOfVotersForPetitioningCampaign,
                    this.base.twoKeyReg.address,
                ]},
                );
                let receipt = await this.utils.getTransactionReceiptMined(txHash);
                let address = receipt.contractAddress;
                resolve(address);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param decentralizedNation
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getAllMembersFromDAO(decentralizedNation:any, from:string) : Promise<IMember[]> {
        /*
        * addresses[]
        * usernames[]: bytes
        * fullnames[]: bytes
        * emails[]: bytes
        * types[]: bytes
        * */
        return new Promise(async(resolve,reject) => {
            try {
                const decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
                const members:IMember[] = [];
                const [ addresses, usernames, fullnames, emails, types ] = await promisify(decentralizedNationInstance.getAllMembers, [{from}]);
                const l = addresses.length;
                for (let i = 0; i < l; i++) {
                    members.push({
                        address: addresses[i],
                        username: this.base.web3.toUtf8(usernames[i]),
                        fullname: this.base.web3.toUtf8(fullnames[i]),
                        email: this.base.web3.toUtf8(emails[i]),
                        type: this.base.web3.toUtf8(types[i]),
                    });
                }
                resolve(members)
            } catch (e) {
                reject(e);
            }
        });
    }


    /**
     *
     * @param decentralizedNation
     * @param {string} memberType
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getAllMembersForSpecificType(decentralizedNation:any, memberType:string, from:string) : Promise<any> {
        return new Promise(async(resolve,reject) => {
           try {
                let decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
               memberType = this.base.web3.toHex(memberType);
                let allMembersForType = await promisify(decentralizedNationInstance.getAllMembersForType,[memberType,{from}]);
                resolve(allMembersForType);
           } catch (e) {
               reject(e);
           }
        });
    }

    /**
     *
     * @param decentralizedNation
     * @param {string} address
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getVotingPointsForTheMember(decentralizedNation: any, address: string, from: string) : Promise<number> {
        return new Promise (async(resolve,reject) => {
            try {
                let decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
                let votingPoints = await promisify(decentralizedNationInstance.getMembersVotingPoints,[address,{from}]);
                resolve(votingPoints);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param decentralizedNation
     * @param {string} newMemberAddress
     * @param {string} memberType
     * @param {string} from
     * @returns {Promise<string>}
     */
    public addMemberByFounder(decentralizedNation: any, newMemberAddress: string, memberType:string, from:string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
           try {
               memberType = this.base.web3.toHex(memberType);
               let decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
               let txHash = await promisify(decentralizedNationInstance.addMembersByFounders,[newMemberAddress,memberType,{from}]);
               resolve(txHash);
           } catch (e) {
               reject(e);
           }
        });
    }


    /**
     *
     * @param decentralizedNation
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getNameAndIpfsHashesForDAO(decentralizedNation: any, from: string) : Promise<any> {
        return new Promise( async(resolve, reject) => {
            try {
                let decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
                let data = await promisify(decentralizedNationInstance.getNameAndIpfsHashes,[{from}]);
                resolve(data);
            } catch (e) {
                reject(e);
            }
        })
    }
}