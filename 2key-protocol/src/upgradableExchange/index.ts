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
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getRate(from: string) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                let dolarRate = await promisify(this.base.twoKeyUpgradableExchange.rate,[{from}]);
                dolarRate = dolarRate / 1000;
                resolve(dolarRate);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<string>}
     */
    public getERC20Token(from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const erc20Address = await promisify(this.base.twoKeyUpgradableExchange.token,[{from}]);
                resolve(erc20Address);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     *
     * @param {string} from
     * @returns {Promise<string>}
     */
    public getAdmin(from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const admin = await promisify(this.base.twoKeyUpgradableExchange.admin,[{from}]);
                resolve(admin);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getWeiRaised(from: string) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const weiRaised = await promisify(this.base.twoKeyUpgradableExchange.weiRaised, [{from}]);
                resolve(weiRaised);
            } catch (e) {
                reject(e);
            }
        })
    }

}