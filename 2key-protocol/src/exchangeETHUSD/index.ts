import {ITwoKeyExchangeContract, RateObject} from "./interfaces";
import {ITwoKeyBase, ITwoKeyHelpers} from "../interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {promisify} from '../utils/promisify';
import {BigNumber} from "bignumber.js";

export default class TwoKeyExchangeContract implements ITwoKeyExchangeContract {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;

    /**
     *
     * @param {ITwoKeyBase} twoKeyProtocol
     * @param {ITwoKeyHelpers} helpers
     * @param {ITwoKeyUtils} utils
     */
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
    public getRatesETHFiat(currency: string, from: string) : Promise<RateObject> {
        return new Promise<RateObject>(async(resolve,reject) => {
            try {
                let rateObject: RateObject = await promisify(this.base.twoKeyExchangeContract.getFiatCurrencyDetails,[currency, {from}]);
                resolve(rateObject);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} currency
     * @param {boolean} isGreater
     * @param {number} price
     * @param {string} from
     * @returns {Promise<string>}
     */
    public setValue(currency: string, isGreater: boolean, price: number | string | BigNumber, from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let currencyHex = await this.base.web3.toHex(currency).toString();
                console.log(currencyHex);
                let txHash = await promisify(this.base.twoKeyExchangeContract.setFiatCurrencyDetails,[currencyHex, isGreater, price, {from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


}
