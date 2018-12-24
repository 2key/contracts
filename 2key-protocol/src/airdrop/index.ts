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
                const airdropInstance = await this.helpers._getAirdropCampaignInstance(airdrop);
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

                let data = {
                    contractor : contractor,
                    inventoryAmount: inventoryAmount,
                    assetContractAddress : assetContractAddress,
                    campaignStartTime : campaignStartTime,
                    campaignEndTime: campaignEndTime,
                    numberOfTokensPerConversion: numberOfTokensPerConversion,
                    numberOfConversions: numberOfConversions,
                    maxNumberOfConversions: maxNumberOfConversions
                };
                resolve(data);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     * This function will get referrer current balance and total earnings, can be called only by contractor or referrer himself
     * @param airdrop
     * @param {string} referrer
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getReferrerBalanceAndTotalEarnings(airdrop: any, referrer: string, from: string) : Promise<any> {
        return new Promise<any>(async(resolve,reject) => {
           try {
               const airdropInstance = await this.helpers._getAirdropCampaignInstance(airdrop);
               let txHash = await promisify(airdropInstance.getReferrerBalanceAndTotalEarnings, [referrer,{from}]);
               resolve(txHash);
           } catch (e) {
               reject(e);
           }
        });
    }


    /**
     * This function will get conversion details, but only if the caller of the method is converter or contractor
     * @param airdrop
     * @param {number} conversionId
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getConversion(airdrop: any, conversionId: number, from: string) : Promise<any> {
        return new Promise<any>(async(resolve,reject) => {
            try {
                const airdropInstance = await this.helpers._getAirdropCampaignInstance(airdrop);
                let [converter, conversionTime, conversionState] = await promisify(airdropInstance.getConversion,
                    [conversionId,{from}]);
                let conversion = {
                    converter : converter,
                    conversionTime: conversionTime,
                    conversionState: this.base.web3.toUtf8(conversionState)
                };
                resolve(conversion);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     * This method can resolve the balance of the converter only if he calls it or contractor
     * @param airdrop
     * @param {string} converter
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getConverterBalance(airdrop: any, converter:string, from:string) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const airdropInstance = await this.helpers._getAirdropCampaignInstance(airdrop);
                let converterBalance = await promisify(airdropInstance.getConverterBalance,[converter,{from}]);
                resolve(converterBalance);
            } catch (e) {
                reject(e);
            }
        });
    }


}
