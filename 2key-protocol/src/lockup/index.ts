import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {promisify} from '../utils';
import {ILockup} from './interfaces';
import {ITwoKeyUtils} from "../utils/interfaces";

export default class Lockup implements ILockup {
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
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getBaseTokensAmount(twoKeyLockup: string, from: string): Promise<number> {
        return new Promise(async(resolve, reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                const baseTokensAmount = await promisify(twoKeyLockupInstance.getBaseTokensAmount, [{from}]);
                resolve(baseTokensAmount);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getBonusTokenAmount(twoKeyLockup: string, from: string): Promise<number> {
        return new Promise(async(resolve, reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                const bonusTokensAmount = await promisify(twoKeyLockupInstance.getTotalBonus, [{from}]);
                resolve(bonusTokensAmount);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<number>}
     */
    public checkIfBaseIsUnlocked(twoKeyLockup: string, from: string): Promise<number> {
        return new Promise(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                const unlocked = await promisify(twoKeyLockupInstance.isBaseUnlocked,[{from}]);
                resolve(unlocked);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getMonthlyBonus(twoKeyLockup: string, from: string): Promise<number> {
        return new Promise(async(resolve, reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                const monthlyBonus = await promisify(twoKeyLockupInstance.getMonthlyBonus,[{from}]);
                resolve(monthlyBonus)
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getAllUnlockedAtTheMoment(twoKeyLockup: string, from:string) : Promise<number> {
        return new Promise(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                const bonusUnlocked = await promisify(twoKeyLockupInstance.getAllUnlockedAtTheMoment,[{from}]);
                resolve(bonusUnlocked);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     *
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getAmountUserWithdrawn(twoKeyLockup: string, from: string) : Promise<number> {
        return new Promise(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                const withdrawn = await promisify(twoKeyLockupInstance.getWithdrawn,[{from}]);
                resolve(withdrawn);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<string>}
     */
    public withdrawTokens(twoKeyLockup: string, from:string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                const txHash = await promisify(twoKeyLockupInstance.transferFungibleAsset, [{from}]);
                await this.utils.getTransactionReceiptMined(txHash);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

}

export { ILockup } from './interfaces';
