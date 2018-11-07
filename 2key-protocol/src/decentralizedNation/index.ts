import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {IDecentralizedNation, IDecentralizedNationConstructor} from "./interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {promisify} from "../utils";

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
    public createDecentralizedNation(data: IDecentralizedNationConstructor, from: string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                const registryAddress = this.base.twoKeyReg.address;
                const txHash = await promisify(this.helpers._createContract,[
                    data.nationName,
                    data.ipfsHashForConstitution,
                    data.ipfsHashForDAOPublicInfo,
                    data.initialMemberAddresses,
                    data.initialMemberTypes,
                    data.limitsPerMemberType,
                    this.base.twoKeyReg.address,
                    { from }
                ]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

}