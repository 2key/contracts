import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {promisify} from '../utils/promisify'
import {IERC20} from './interfaces';
import {ITwoKeyUtils} from "../utils/interfaces";

export default class ERC20 implements IERC20 {
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
     * @param erc20
     * @returns {Promise<string>}
     */
    public getERC20Symbol(erc20: any): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const symbol = await promisify(erc20Instance.symbol, []);
                resolve(symbol);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param erc20
     * @returns {Promise<string>}
     */
    public getTokenName(erc20: any): Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
          try {
              const erc20Instance = await this.helpers._getERC20Instance(erc20);
              const name = await promisify(erc20Instance.name, []);
              resolve(name);
          } catch (e) {
              reject(e);
          }
        })
    }

    /**
     *
     * @param erc20
     * @returns {Promise<string>}
     */
    public getTokenDecimals(erc20: any): Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const name = await promisify(erc20Instance.decimals, []);
                resolve(name.toNubmer());
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param erc20
     * @param {string} tokens_from
     * @param {string} to
     * @param {string} value
     * @param {string} from
     * @returns {Promise<string>}
     */
    public transferFrom(erc20: any, tokens_from: string, to: string, value:string, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const txHash = await promisify(erc20Instance.transferFrom,[tokens_from,to,value,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param erc20
     * @param {string} to
     * @param {string} value
     * @param {string} from
     * @returns {Promise<string>}
     */
    public transfer(erc20:any, to:string, value:string, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const txHash = await promisify(erc20Instance.transfer,[to,value,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     *
     * @param erc20
     * @param {string} address
     * @returns {Promise<number>}
     */
    public getERC20Balance(erc20: any, address: string): Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const balance = await promisify(erc20Instance.balanceOf, [address]);
                resolve(balance);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param erc20
     * @returns {Promise<number>}
     */
    public getTotalSupply(erc20: any) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const totalSupply_ = await promisify(erc20Instance.totalSupply,[]);
                const decimals = await promisify(erc20Instance.decimals,[]);
                resolve(parseFloat((this.utils.fromWei(totalSupply_,decimals.toNumber())).toString()));
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param erc20
     * @param {string} address
     * @param {string} spenderAddress
     * @param {number} value
     * @param {string} from
     * @returns {Promise<string>}
     */
    public erc20ApproveAddress(erc20:any, address:string, spenderAddress: string, value:number, from: string): Promise<string> {
        return new Promise(async (resolve,reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const txHash = await promisify(erc20Instance.approve,[spenderAddress,value, {from, nonce}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }
}

export { IERC20 } from './interfaces';
