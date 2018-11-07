import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {IDecentralizedNation, IDecentralizedNationConstructor} from "./interfaces";
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

    public createDecentralizedNation(data: IDecentralizedNationConstructor, from: string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                const txHash = await this.helpers._createContract(contracts.DecentralizedNation ,from, {params: [
                    data.nationName,
                    this.base.web3.toHex(data.ipfsHashForConstitution),
                    this.base.web3.toHex(data.ipfsHashForDAOPublicInfo),
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

    public getAllMembersFromDAO(decentralizedNation:any, from:string) : Promise<any> {
        return new Promise(async(resolve,reject) => {
            try {
                let decentralizedNationInstance = await this.helpers._getDecentralizedNationInstance(decentralizedNation);
                let allMembers = await promisify(decentralizedNationInstance.getAllMembers, [{from}]);
                resolve(allMembers)
            } catch (e) {
                reject(e);
            }
        });
    }

}