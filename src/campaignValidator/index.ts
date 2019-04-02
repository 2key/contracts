import {ITwoKeyCampaignValidator} from "./interfaces";
import {ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from "../interfaces";
import {promisify} from '../utils/promisify'

export default class TwoKeyCampaignValidator implements ITwoKeyCampaignValidator {
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
     * @param {string} campaignAddress
     * @param {string} nonSingletonHash
     * @param {string} from
     * @returns {Promise<string>}
     */
    public validateCampaign(campaignAddress: string, nonSingletonHash: string, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let txHash = await promisify(this.base.twoKeyCampaignValidator.validateAcquisitionCampaign,
                    [campaignAddress,nonSingletonHash,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Function which will determine if the campaign address is validated or not
     * @param {string} campaignAddress
     * @returns {Promise<boolean>}
     */
    public isCampaignValidated(campaignAddress:string) : Promise<boolean> {
        return new Promise<boolean>(async(resolve,reject) => {
            try {
                let status = await promisify(this.base.twoKeyCampaignValidator.isCampaignValidated,[campaignAddress]);
                resolve(status);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} campaignAddress
     * @returns {Promise<string>}
     */
    public getCampaignNonSingletonsHash(campaignAddress:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let nonSingletonHash = await promisify(this.base.twoKeyCampaignValidator.campaign2nonSingletonHash,[campaignAddress]);
                resolve(nonSingletonHash);
            } catch (e) {
                reject(e);
            }
        })
    }
}