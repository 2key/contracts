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
    public getCampaignsWhereUserIsConverter(address: string): Promise<string[]> {
        return new Promise<string[]>(async (resolve, reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsConverter, [address]);
                console.log('Campaigns where' + address + 'is converter: ', campaigns);
                resolve(campaigns);
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
    public getCampaignsWhereUserIsContractor(address: string) : Promise<string[]> {
        return new Promise<string[]>(async (resolve,reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsContractor,[address]);
                console.log('Campaigns where : ' + address + 'is contractor: ' +  campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getCampaignsWhereUserIsModerator(address: string) : Promise<string[]> {
        return new Promise(async (resolve,reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsModerator,[address]);
                console.log('Campaigns where : ' + address + 'is moderator: ' + campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getCampaignsWhereUserIsReferrer(address: string) : Promise<string[]> {
        return new Promise(async (resolve,reject) => {
            try {
                const campaigns = await promisify(this.base.twoKeyReg.getContractsWhereUserIsReferrer,[address]);
                console.log('Campaigns where: '+ address + 'is referrer: ' + campaigns);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        })
    }
}