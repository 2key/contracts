import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {promisify} from '../utils'
import Sign from '../utils/sign';
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
    public signPlasmaToEthereum(from: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                let plasmaAddress = this.base.plasmaAddress;
                let storedEthAddress = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [plasmaAddress]);
                console.log('PLASMA.signPlasmaToEthereum storedETHAddress', storedEthAddress);
                if (storedEthAddress != from) {
                    let plasma2ethereum_sig = await Sign.sign_plasma2ethereum(this.base.web3, this.base.plasmaAddress, from);
                    resolve(plasma2ethereum_sig);
                } else {
                    reject(new Error('Already registered on plasma network!'));
                }

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
    public setPlasmaToEthereumOnPlasma(from: string): Promise<string | boolean> {
        return new Promise<string | boolean>(async (resolve, reject) => {
            let plasma2ethereum_sig;
            try {
                plasma2ethereum_sig = await this.signPlasmaToEthereum(from);
                let txHash = await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum, [plasma2ethereum_sig,
                    {
                        from: this.base.plasmaAddress
                    }]);
                resolve(txHash);
            } catch (e) {
                if (!plasma2ethereum_sig) {
                    resolve(false);
                } else {
                    reject(e);
                }
            }
        })
    }
}