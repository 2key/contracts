import {ICampaignData, ICreateCampaign, IDonationCampaign, InvoiceERC20} from "./interfaces";
import {ICreateOpts, IERC20, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from "../interfaces";
import {ISign} from "../sign/interface";
import donationContracts, {default as donation} from '../contracts/donation';
import { promisify } from '../utils/promisify';
import acquisitionContracts from "../contracts/acquisition";



export default class DonationCampaign implements IDonationCampaign {
    public readonly nonSingletonsHash: string;
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;
    private readonly erc20: IERC20;
    private readonly sign: ISign;
    private DonationCampaign: any;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils, erc20: IERC20, sign: ISign) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
        this.erc20 = erc20;
        this.sign = sign;
        this.nonSingletonsHash = donationContracts.NonSingletonsHash;
    }

    /**
     * Function to get Donation campaign instance
     * @param campaign
     * @param {boolean} skipCache
     * @returns {Promise<any>}
     * @private
     */
    async _getCampaignInstance(campaign: any, skipCache?: boolean): Promise<any> {
        const address = campaign.address || campaign;
        this.base._log('Requesting TwoKeyDonationCampaign at', address);
        if (skipCache) {
            const campaignInstance = await this.helpers._createAndValidate(donationContracts.TwoKeyDonationCampaign.abi, campaign);
            return campaignInstance;
        }
        if (this.DonationCampaign && this.DonationCampaign.address === address) {
            this.base._log('Return from cache TwoKeyDonationCampaign at', this.DonationCampaign.address);
            return this.DonationCampaign;
        }
        this.base._log('Instantiate new TwoKeyDonationCampaign at', address, this.DonationCampaign);
        if (campaign.address) {
            this.DonationCampaign = campaign;
        } else {
            this.DonationCampaign = await this.helpers._createAndValidate(donationContracts.TwoKeyDonationCampaign.abi, campaign);
        }

        return this.DonationCampaign;
    }

    /**
     *
     * @param {ICreateCampaign} data
     * @param {string} from
     * @param {ICreateCampaignProgress} progressCallback
     * @param {number} gasPrice
     * @param {number} interval
     * @param {number} timeout
     * @returns {Promise<string>}
     */
    public create(data: ICreateCampaign, from: string, {progressCallback, gasPrice, interval, timeout = 60000}: ICreateOpts = {}): Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let txHash: string = await this.helpers._createContract(donationContracts.TwoKeyDonationCampaign, from, {
                    gasPrice,
                    params: [
                        data.moderator,
                        data.campaignName,
                        data.publicMetaHash,
                        data.privateMetaHash,
                        data.invoiceToken.tokenName,
                        data.invoiceToken.tokenSymbol,
                        data.campaignStartTime,
                        data.campaignEndTime,
                        data.minDonationAmount,
                        data.maxDonationAmount,
                        data.campaignGoal,
                        data.conversionQuota,
                        this.base.twoKeySingletonesRegistry.address,
                        data.incentiveModel
                    ],
                    progressCallback,
                    link: [
                        {
                            name: 'Call',
                            address: this.base.twoKeyCall.address,
                        },
                        {
                            name: 'IncentiveModels',
                            address: this.base.twoKeyIncentiveModel.address
                        }
                    ],
                });

                const campaignReceipt = await this.utils.getTransactionReceiptMined(txHash, {
                    web3: this.base.web3,
                    interval,
                    timeout
                });
                if (campaignReceipt.status !== '0x1') {
                    reject(campaignReceipt);
                    return;
                }
                const campaignAddress = campaignReceipt && campaignReceipt.contractAddress;
                if (progressCallback) {
                    progressCallback('TwoKeyDonationCampaign', true, campaignAddress);
                }
                console.log('Campaign created', campaignAddress);

                // const campaignPublicLinkKey = await this.join(campaignAddress, from, {gasPrice, progressCallback, interval, timeout});
                // if (progressCallback) {
                //     progressCallback('SetPublicLinkKey', true, campaignPublicLinkKey);
                // }
                resolve(campaignAddress);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     *
     * @param {string} campaignAddress
     * @returns {Promise<ICampaignData>}
     */
    public getContractData(campaignAddress: string) : Promise<ICampaignData> {
        return new Promise<ICampaignData>(async(resolve,reject) => {
            try {
                let donationCampaignInstance = await this._getCampaignInstance(campaignAddress);
                let data = await promisify(donationCampaignInstance.getCampaignData,[]);
                console.log(data);
                let campaignStartTime = parseInt(data.slice(0,66),16);
                let campaignEndTime = parseInt(data.slice(66,66+64), 16);
                let minDonationAmount = parseInt(data.slice(66+64,66+64+64),16);
                let maxDonationAmount = parseInt(data.slice(66+64+64,66+64+64+64),16);
                let maxReferralRewardPercent = parseInt(data.slice(66+64+64+64,66+64+64+64+64),16);
                let campaignName = "";
                let publicMetaHash = "";
                let obj : ICampaignData = {
                    campaignStartTime,
                    campaignEndTime,
                    minDonationAmount,
                    maxDonationAmount,
                    maxReferralRewardPercent,
                    campaignName,
                    publicMetaHash
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }


}