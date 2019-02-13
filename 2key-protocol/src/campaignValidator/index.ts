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
     * Function which should be called by contractor of campaign in order to proof that the campaign is valid
     * @param {string} address
     * @param {string} from
     * @returns {Promise<string>}
     */
    public validateCampaign(campaignAddress: string, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let txHash = await promisify(this.base.twoKeyCampaignValidator.validateAcquisitionCampaign,
                    [campaignAddress,{from}]);
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
}