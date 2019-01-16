import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {promisify} from '../utils'
import Sign from '../utils/sign';
import {strict} from "assert";
import {IPlasmaEvents} from "./interfaces";

export default class PlasmaEvents implements IPlasmaEvents {
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
     * @returns {Promise<string>}
     */
    public setPlasmaToEthereumOnPlasma(from: string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                let txHash = "";
                let plasmaAddress = this.base.plasmaAddress;
                let storedEthAddress = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum,[plasmaAddress]);
                if(storedEthAddress != from) {
                    let plasma2ethereum_sig = await Sign.sign_plasma2ethereum(this.base.plasmaWeb3,this.base.plasmaAddress, from);
                    txHash = await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum,[plasma2ethereum_sig,
                        {
                            from: this.base.plasmaAddress
                        }]);
                }
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

}