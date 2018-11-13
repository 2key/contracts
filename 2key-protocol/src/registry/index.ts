import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {promisify} from '../utils'
import {ITwoKeyReg} from "./interfaces";

export default class TwoKeyReg implements ITwoKeyReg {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
    }


    /**
     *
     * @param {string} address
     * @param {string} from
     * @returns {Promise<boolean>}
     */
    public checkIfUserIsRegistered(address: string, from: string) : Promise<boolean> {
        return new Promise(async(resolve,reject) => {
            try {
                let isRegistered = await promisify(this.base.twoKeyReg.checkIfUserExists,[address, {from}]);
                resolve(isRegistered);
            } catch (e) {
                reject(e);
            }
        });
    }


    /**
     *
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getCampaignsWhereConverter(from: string): Promise<string[]> {
        return new Promise<string[]>(async (resolve, reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsConverter, [from]);
                console.log('Converter campaigns: ', campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        });
    }



}