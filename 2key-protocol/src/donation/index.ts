import {ICreateCampaign, IDonationCampaign, InvoiceERC20} from "./interfaces";
import {ICreateOpts, IERC20, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from "../interfaces";
import {ISign} from "../sign/interface";
import donationContracts from '../contracts/donation';


export default class DonationCampaign implements IDonationCampaign {
    public readonly nonSingletonsHash: string;
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;
    private readonly erc20: IERC20;
    private readonly sign: ISign;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils, erc20: IERC20, sign: ISign) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
        this.erc20 = erc20;
        this.sign = sign;
        this.nonSingletonsHash = donationContracts.NonSingletonsHash;
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
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


}