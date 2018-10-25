import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {promisify} from '../utils'

export default class ERC20 {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    // private readonly utils: ITWoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        // this.utils = utils;
    }

    public getERC20Symbol(erc20: any): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const symbol = await promisify(erc20Instance.symbol, [{ from: this.base.address }]);
                resolve(symbol);
            } catch (e) {
                reject(e);
            }
        });
    }

    public erc20ApproveAddres(erc20:any, address:string, spenderAddress: string, value:number) : Promise<string> {
        return new Promise(async (resolve,reject) => {
            try {
                const erc20Instance = await this.helpers._getERC20Instance(erc20);
                const txHash = await promisify(erc20Instance.approve,[spenderAddress,value, {from: this.base.address}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


}
