import {ITwoKeyExchangeContract} from "./interfaces";
import {ITwoKeyBase, ITwoKeyHelpers} from "../interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {promisify} from "../utils";

export default class TwoKeyExchangeContract implements ITwoKeyExchangeContract {
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
    public getValue(from: string) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                let rate = await promisify(this.base.twoKeyExchangeContract.getPrice,[{from}]);
                resolve(rate);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @param {number} price
     * @returns {Promise<string>}
     */
    public setValue(from: string, price:number) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let txHash = await promisify(this.base.twoKeyExchangeContract.setPrice,[price, {from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


}
