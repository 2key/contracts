import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {promisify} from '../utils';
import {ILockup, LockupInformation} from './interfaces';
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
     * Get information from the Lockup contract, it's only available for the Converter
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<LockupInformation>}
     */
    public getLockupInformations(twoKeyLockup: string, from:string) : Promise<LockupInformation> {
        return new Promise<LockupInformation>(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);

                let [baseTokens, bonusTokens, vestingMonths, unlockingDates, isWithdrawn] =
                    await promisify(twoKeyLockupInstance.getLockupSummary,[{from}]);
                let obj : LockupInformation = {
                    baseTokens : parseFloat(this.utils.fromWei(baseTokens, 'ether').toString()),
                    bonusTokens : parseFloat(this.utils.fromWei(bonusTokens, 'ether').toString()),
                    vestingMonths : vestingMonths.toNumber(),
                    unlockingDays : unlockingDates.map(date => parseInt(date.toString(),10)),
                    areWithdrawn : isWithdrawn
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Method to withdraw tokens, converter is sending which part he wants to withdraw - only converter can call this
     * @param {string} twoKeyLockup
     * @param {number} part
     * @param {string} from
     * @returns {Promise<string>}
     */
    public withdrawTokens(twoKeyLockup: string, part: number, from:string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                const txHash = await promisify(twoKeyLockupInstance.withdrawTokens, [part,{from}]);
                // await this.utils.getTransactionReceiptMined(txHash);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }




    /**
     * Only contractor can change token distribution date
     * @param {string} twoKeyLockup
     * @param {number} newDate
     * @param {string} from
     * @returns {Promise<string>}
     */
    public changeTokenDistributionDate(twoKeyLockup: string, newDate: number, from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                let txHash = await promisify(twoKeyLockupInstance.changeTokenDistributionDate,[newDate,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


}

export { ILockup } from './interfaces';
