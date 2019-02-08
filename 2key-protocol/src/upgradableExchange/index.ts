import {IUpgradableExchange} from "./interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {ITwoKeyBase, ITwoKeyHelpers} from "../interfaces";
import {promisify} from '../utils/promisify';


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


    /**
     *
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getTransactionCount(from: string) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const transactionCount = await promisify(this.base.twoKeyUpgradableExchange.transactionCounter,[{from}]);
                resolve(transactionCount);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} from
     * @param {string} contractAddress
     * @returns {Promise<string>}
     */
    public addContractToBeEligibleToGetTokensFromExchange(contractAddress: string, from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const addContractHash = await promisify(this.base.twoKeyUpgradableExchange.addContractToBeEligibleToBuyTokens,[contractAddress,{from}]);
                resolve(addContractHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} contractAddress
     * @returns {Promise<boolean>}
     */
    public checkIfContractIsEligibleToBuyTokens(contractAddress: string) : Promise<boolean> {
        return new Promise<boolean>(async(resolve,reject) => {
            try {
                const isEligible = await promisify(this.base.twoKeyUpgradableExchange.isContractAddressEligibleToBuyTokens,[contractAddress]);
                resolve(isEligible);
            } catch (e) {
                reject(e);
            }
        })
    }

}