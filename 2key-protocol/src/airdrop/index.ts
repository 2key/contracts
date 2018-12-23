import {ITwoKeyAirDropCampaign} from "./interfaces";
import {IERC20, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from "../interfaces";
import {promisify} from '../utils';

export default class AcquisitionCampaign implements ITwoKeyAirDropCampaign {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;
    private readonly erc20: IERC20;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils, erc20: IERC20) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
        this.erc20 = erc20;
    }

    /**
     * Function to get static and dynamic informations about the airdrop contract
     * @param airdrop
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getContractInformations(airdrop: any, from: string) : Promise<any> {
        return new Promise<any>(async(resolve,reject) => {
            try {
                let airdropInstance = await this.helpers._getAirdropCampaignInstance(airdrop);
                let campaignInformations : string = await promisify(airdropInstance.getContractInformations,[{from}]);
                // TODO: Think about creating method in helpers which will work modular just by providing expected types and returning object
                let contractor = campaignInformations.slice(0,42);
                let inventoryAmount = parseInt(campaignInformations.slice(42, 42+64),16);
                let assetContractAddress = '0x' + campaignInformations.slice(42+64, 42+64+42);
                let campaignStartTime = parseInt(campaignInformations.slice(42+64+40,42+64+40+64),16);
                let campaignEndTime = parseInt(campaignInformations.slice(42+64+40+64, 42+64+40+64+64),16);
                let numberOfTokensPerConversion = parseInt(campaignInformations.slice(42+64+40+64+64,42+64+40+64+64+64),16);
                let numberOfConversions = parseInt(campaignInformations.slice(42+64+40+64+64+64, 42+64+40+64+64+64+64),16);
                let maxNumberOfConversions = parseInt(campaignInformations.slice(42+64+40+64+64+64+64, 42+64+40+64+64+64+64+64),16);

                let obj = {
                    contractor : contractor,
                    inventoryAmount: inventoryAmount,
                    assetContractAddress : assetContractAddress,
                    campaignStartTime : campaignStartTime,
                    campaignEndTime: campaignEndTime,
                    numberOfTokensPerConversion: numberOfTokensPerConversion,
                    numberOfConversions: numberOfConversions,
                    maxNumberOfConversions: maxNumberOfConversions
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        });
    }

}
