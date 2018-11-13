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
}

export { ILockup } from './interfaces';
