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
                    data.ipfsHashForConstitution,
                    data.ipfsHashForDAOPublicInfo,
                    data.initialMemberAddresses,
                    data.initialMemberTypes,
                    data.limitsPerMemberType,
                    this.base.twoKeyReg.address,
                ]},
                );
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

}