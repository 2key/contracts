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
                // await this.utils.getTransactionReceiptMined(txHash);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getInformationFromLockup(twoKeyLockup: string, from: string) : Promise<any> {
        return new Promise<any>(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                let [baseTokens, bonusTokens, vestingMonths, withdrawn, totalTokensLeft, allUnlockedAtTheMoment]
                    = await promisify(twoKeyLockupInstance.getInformation,[{from}]);
                let obj = {
                    'baseTokens' : baseTokens,
                    'bonusTokens' : bonusTokens,
                    'vestingMonths' : vestingMonths,
                    'withdrawn' : withdrawn,
                    'totalTokensLeft' : totalTokensLeft,
                    'allUnlockedAtTheMoment' : allUnlockedAtTheMoment
                };
                resolve(obj);
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



    /**
     *
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getStatistics(twoKeyLockup: string, from:string) : Promise<any> {
        return new Promise(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this.helpers._getLockupContractInstance(twoKeyLockup);
                let [baseTokens, bonusTokens, vestingMonths, withdrawn, totalTokensLeft, allUnlockedAtTheMoment]
                    = await promisify(twoKeyLockupInstance.getInformation,[{from}]);

                let monthlyBonus = bonusTokens/vestingMonths;
                console.log('Bonus tokens: ' + bonusTokens);
                console.log('Withdrawn: ' + withdrawn);
                console.log('Base Tokens: ' + baseTokens);
                console.log('Total tokens left on the contract: ' + totalTokensLeft);
                console.log('Vesting months: ' + vestingMonths);
                console.log('Monthly bonus: '+  monthlyBonus);
                console.log('All unlocked at the moment :' + allUnlockedAtTheMoment);

                let stats = [];
                let statObject;
                let sum = 0;
                if(withdrawn == 0) {
                    statObject = {
                        'amount' : baseTokens,
                        'taken' : false,
                    };
                } else {
                    statObject = {
                        'amount' : baseTokens,
                        'taken' : true,
                    };
                    sum = baseTokens;
                }

                stats.push(statObject);
                console.log('Sum is: ' + sum);
                for(let i=0; i<vestingMonths; i++) {
                    if(sum + monthlyBonus > withdrawn) {
                        statObject = {
                            'amount' : monthlyBonus,
                            'taken' : false,
                        }
                    } else {
                        statObject = {
                            'amount' : monthlyBonus,
                            'taken' : true,
                        };
                        sum += monthlyBonus;
                    }
                    stats.push(statObject);
                }
                resolve(stats);
            } catch (e) {
                reject(e);
            }
        })
    }

}

export { ILockup } from './interfaces';
