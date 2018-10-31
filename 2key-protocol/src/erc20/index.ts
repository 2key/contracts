import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {promisify} from '../utils'
import {IERC20} from './interfaces';

export default class ERC20 implements IERC20 {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    // private readonly utils: ITwoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        // this.utils = utils;
    }

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
