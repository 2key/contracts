import {IUpgradableExchange} from "./interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {ITwoKeyBase, ITwoKeyHelpers} from "../interfaces";
import {promisify} from '../utils';


export default class UpgradableExchange implements IUpgradableExchange {

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
     * @param upgradableExchange
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getRate(upgradableExchange: any, from: string) : Promise<number> {
        return new Promise(async(resolve,reject) => {
            try {
                const instance = await this.helpers._getUpgradableExchangeInstance(upgradableExchange);
                const rate = await promisify(instance.rate,[{from}]);
                resolve(rate);
            } catch (e) {
                reject(e);
            }
        })
    }

}