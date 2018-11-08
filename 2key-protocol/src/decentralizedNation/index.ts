import {ICreateOpts, ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {
    IDaoMeta,
    IDecentralizedNation,
    IDecentralizedNationConstructor,
    IMember,
    INationalVotingCampaign,
    IVotingCampaign
} from "./interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {promisify} from "../utils";
import contracts from '../contracts';
import {ITwoKeyWeightedVoteConstructor} from "../veightedVote/interfaces";
import {ITwoKeyWeightedVoteContract} from "../veightedVote";

export default class DecentralizedNation implements IDecentralizedNation {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;
    private readonly veightedVode: ITwoKeyWeightedVoteContract;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils, veightedVote: ITwoKeyWeightedVoteContract) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
        this.veightedVode = veightedVote;
    }

    _convertMembersFromBytes(members: any): IMember[] {
        const result: IMember[] = [];
        const [ addresses, usernames, fullnames, emails, types ] = members;
        const l = addresses.length;
        for (let i = 0; i < l; i++) {
            result.push({
                address: addresses[i],
                username: this.base.web3.toUtf8(usernames[i]),
                fullname: this.base.web3.toUtf8(fullnames[i]),
                email: this.base.web3.toUtf8(emails[i]),
                type: this.base.web3.toUtf8(types[i]),
            });
        }
        return result;
    }

    /**
     *
     * @param {IDecentralizedNationConstructor} data
     * @param {string} from
     * @returns {Promise<string>}
     */
    public check(address: string, from: string): Promise<boolean> {
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
    public create(data: IDecentralizedNationConstructor, from: string, { gasPrice, progressCallback, interval, timeout = 60000 }: ICreateOpts = {}) : Promise<string> {
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
                ],
                    gasPrice,
                    progressCallback, },
                );
                let receipt = await this.utils.getTransactionReceiptMined(txHash, { interval, timeout, web3: this.base.web3 });
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
    public getAllMembersFromDAO(decentralizedNation:any) : Promise<IMember[]> {
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
                // const members:IMember[] = [];
                // const [ addresses, usernames, fullnames, emails, types ] = await promisify(decentralizedNationInstance.getAllMembers, [{from}]);
                const members = this._convertMembersFromBytes(await promisify(decentralizedNationInstance.getAllMembers, []));
                // const l = addresses.length;
                // for (let i = 0; i < l; i++) {
                //     members.push({
                //         address: addresses[i],
                //         username: this.base.web3.toUtf8(usernames[i]),
                //         fullname: this.base.web3.toUtf8(fullnames[i]),
                //         email: this.base.web3.toUtf8(emails[i]),
                //         type: this.base.web3.toUtf8(types[i]),
                //     });
                // }
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
               console.log(txHash);
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
    public getNameAndIpfsHashesForDAO(decentralizedNation: any) : Promise<IDaoMeta> {
        return new Promise( async(resolve, reject) => {
            try {
                const decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
                const [name, constitution, metaIPFS] = await promisify(decentralizedNationInstance.getNameAndIpfsHashes,[]);
                console.log(name, constitution, metaIPFS);
                const meta = JSON.parse((await promisify(this.base.ipfs.cat, [metaIPFS])).toString());
                resolve({
                    name,
                    constitution,
                    meta,
                });
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param decentralizedNation
     * @param {INationalVotingCampaign} data
     * @param {string} from
     * @param {number} gasPrice
     * @param {ICreateCampaignProgress} progressCallback
     * @param {number} interval
     * @param {number} timeout
     * @returns {Promise<string>}
     */
    public createCampaign(decentralizedNation: any, data: INationalVotingCampaign, from: string, { gasPrice, progressCallback, interval, timeout = 60000 }: ICreateOpts = {}) : Promise<any> {
        return new Promise(async(resolve, reject) => {
            try{
                const decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
                const dataForVotingContract : ITwoKeyWeightedVoteConstructor = {
                    descriptionForVoting: data.votingReason,
                    addressOfDAO: decentralizedNationInstance.address
                };

                let addressOfVotingContract = await this.veightedVode.createWeightedVoteContract(dataForVotingContract, from, {
                    gasPrice, progressCallback, interval, timeout
                });

                let txHash = await promisify(decentralizedNationInstance.startCampagin,[
                    data.votingReason,
                    data.campaignLengthInDays,
                    addressOfVotingContract,
                    data.flag,
                    {
                        from,
                        gasPrice,
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
     * @param decentralizedNation
     * @param {string} memberType
     * @returns {Promise<boolean>}
     */
    public isTypeEligibleToCreateAVotingCampaign(decentralizedNation: any, memberType: string) : Promise<boolean> {
        return new Promise(async(resolve,reject) => {
            try {
                memberType = this.base.web3.toHex(memberType);
                let decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
                let isEligible = await promisify(decentralizedNationInstance.isMemberTypeEligibleToCreateVotingCampaign, [memberType]);
                resolve(isEligible);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param decentralizedNation
     * @returns {Promise<any>}
     */

    public getAllCampaigns(decentralizedNation:any) : Promise<IVotingCampaign[]> {
        return new Promise(async(resolve,reject) => {
           try {
               let decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
               let numberOfCampaigns = await promisify(decentralizedNationInstance.getNumberOfVotingCampaigns,[]);
               const promises = [];
               for (let i=0; i<numberOfCampaigns; i++) {
                   promises.push(new Promise(async (cResolve, cReject) => {
                       let nvcAddress = await promisify(decentralizedNationInstance.allCampaigns,[i]);
                       let [votingReason, finished, votesYes, votesNo, votingResultForYes, votingResultForNo, votingCampaignLengthInDays, campaignType, votingCampaignContractAddress]
                           = await promisify(decentralizedNationInstance.getCampaign,[i]);
                       votesYes = votesYes.toNumber();
                       votesNo = votesNo.toNumber();
                       votingResultForYes = votingResultForYes.toNumber();
                       votingResultForNo = votingResultForNo.toNumber();
                       votingCampaignLengthInDays = new Date(votingCampaignLengthInDays.toNumber());
                       campaignType = this.base.web3.toUtf8(campaignType);
                       cResolve({
                           votingReason, finished, votesYes, votesNo, votingResultForYes, votingResultForNo, votingCampaignLengthInDays, campaignType, votingCampaignContractAddress,
                       });
                   }));
               }
               resolve(await Promise.all(promises));
           } catch(e) {
               reject(e);
           }
        });
    }
}