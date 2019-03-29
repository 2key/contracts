import {ITwoKeySingletonRegistry} from "./interfaces";
import {ITwoKeyBase, ITwoKeyHelpers} from "../interfaces";
import {ITwoKeyUtils} from "../utils/interfaces";
import {promisify} from '../utils/promisify';


export default class TwoKeySingletonRegistry implements ITwoKeySingletonRegistry {
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
     * @param {string[]} addresses
     * @param {number[]} valuesConversion
     * @param {number[]} valuesLogicHandler
     * @param {number[]} valuesCampaign
     * @param {string} currency
     * @param {string} from
     * @returns {Promise<any>}
     */
    public createProxiesForAcquisitions(
        addresses: string[],
        valuesConversion: number[],
        valuesLogicHandler: any[],
        valuesCampaign: any[],
        currency: string,
        from: string
    ) : Promise<any> {
        return new Promise<any>(async(resolve,reject) => {
            try {
                console.log('Contractor should be: ' + from);
                let txHash = await promisify(this.base.twoKeySingletonesRegistry.createProxiesForAcquisitions,
                    [
                        addresses,
                        valuesConversion,
                        valuesLogicHandler,
                        valuesCampaign,
                        currency,
                        {
                            from
                        }
                    ]);
                let receipt = await this.utils.getTransactionReceiptMined(txHash);
                console.log(receipt.logs[0].data);

                let proxyLogic = '0x' + receipt.logs[0].data.slice(26,66);
                let proxyConversion = '0x' + receipt.logs[0].data.slice(66+24, 66+24+40);
                let proxyAcquisition = '0x' + receipt.logs[0].data.slice(66+24+40+24);
                // let { proxyLogic, proxyConversion, proxyAcquisition } = logs.find(l => l.event === 'ProxyForCampaign').args
                resolve({
                    'campaignAddress': proxyAcquisition,
                    'conversionHandlerAddress': proxyConversion,
                    'twoKeyAcquisitionLogicHandlerAddress': proxyLogic
                });
            } catch (e) {
                reject(e);
            }
        })
    }
}
