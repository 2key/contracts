import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {promisify} from '../utils'
import Sign from '../utils/sign';
import {IPlasmaEvents, ISignedEthereum, IVisits} from "./interfaces";

export default class PlasmaEvents implements IPlasmaEvents {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
    }

    public getRegisteredAddressForPlasma(plasma: string = this.base.plasmaAddress): Promise<string> {
        return promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [plasma])
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
                let storedEthAddress = await this.getRegisteredAddressForPlasma(plasmaAddress);
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

    public getVisitsList(campaignAddress: string, contractorAddress: string, address: string): Promise<IVisits> {
        return new Promise<IVisits>(async (resolve, reject) => {
            try {
                let [visits, timestamps] = await promisify(this.base.twoKeyPlasmaEvents.visitsListEx, [campaignAddress, contractorAddress, address]);
                resolve({
                    visits,
                    timestamps: timestamps.map(time => time * 1000),
                });
            } catch (e) {
                reject(e);
            }
        })
    }
    public getVisitedFrom(campaignAddress: string, contractorAddress: string, address: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                let visitedFrom = promisify(this.base.twoKeyPlasmaEvents.getVisitedFrom, [campaignAddress, contractorAddress, address]);
                resolve(visitedFrom);
            } catch (e) {
                reject(e);
            }
        })
    }

    public getJoinedFrom(campaignAddress: string, contractorAddress: string, address: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                // let visitedFrom = promisify(this.base.twoKeyPlasmaEvents.getJoinedFrom, [campaignAddress, contractorAddress, address]);
                let joinedFrom = promisify(this.base.twoKeyPlasmaEvents.joined_from, [campaignAddress, contractorAddress, address]);
                resolve(joinedFrom);
            } catch (e) {
                reject(e);
            }
        })
    }
}