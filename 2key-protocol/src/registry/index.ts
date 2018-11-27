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


    /**
     *
     * @returns {Promise<string[]>}
     */
    public getRegistryMaintainers() : Promise<string[]> {
        return new Promise(async(resolve,reject) => {
            try {
                const maintainers = await promisify(this.base.twoKeyReg.getMaintainers,[]);
                console.log('Maintainers in registry contract are: '+ maintainers);
                resolve(maintainers);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} username
     * @param {string} address
     * @param {string} username_walletName
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public setWalletName(username: string, address: string, username_walletName: string, from: string, gasPrice: number = this.base._getGasPrice()) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const txHash = await promisify(this.base.twoKeyReg.setWalletName,
                    [
                        username,
                        address,
                        username_walletName,
                        {
                            from,
                            gasPrice,
                            nonce
                        }
                    ]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }


}