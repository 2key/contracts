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
     * @param {string} currency
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getValue(currency: string, from: string) : Promise<any> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                let rateObject = await promisify(this.base.twoKeyExchangeContract.getPrice,[currency, {from}]);
                resolve(rateObject);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} currency
     * @param {number} price
     * @param {string} from
     * @returns {Promise<string>}
     */
    public setValue(currency: string, isGreater: boolean, price: number, from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let currencyHex = await this.base.web3.toHex(currency).toString();
                console.log(currencyHex);
                let txHash = await promisify(this.base.twoKeyExchangeContract.setPrice,[currencyHex, isGreater, price, {from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


}
