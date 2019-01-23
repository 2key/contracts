import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {promisify} from '../utils'
import Sign from '../utils/sign';
import {IPlasmaEvents, ISignedEthereum} from "./interfaces";

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
    public signPlasmaToEthereum(from: string): Promise<ISignedEthereum> {
        return new Promise<ISignedEthereum>(async (resolve, reject) => {
            console.log('PLASMA.signPlasmaToEthereum', from);
            try {
                let plasmaAddress = this.base.plasmaAddress;
                let storedEthAddress = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [plasmaAddress]);
                console.log('PLASMA.signPlasmaToEthereum storedETHAddress', storedEthAddress);
                if (storedEthAddress != from) {
                    let plasma2ethereumSignature = await Sign.sign_plasma2ethereum(this.base.web3, plasmaAddress, from);
                    resolve({
                        plasmaAddress,
                        plasma2ethereumSignature
                    });
                } else {
                    reject(new Error('Already registered!'));
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
    public setPlasmaToEthereumOnPlasma(plasmaAddress: string, plasma2EthereumSignature: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                let txHash = await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum, [plasmaAddress, plasma2EthereumSignature,
                    {
                        from: this.base.plasmaAddress
                    }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }
}