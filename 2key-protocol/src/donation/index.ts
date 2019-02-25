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
        //TODO: Generate non singletone hash
    }

    /**
     * moderator: string,
     campaignName: string,
     publicMetaHash: string,
     privateMetaHash: string,
     invoiceToken: InvoiceERC20,
     campaignStartTime: number,
     campaignEndTime: number,
     minDonationAmount: number,
     maxDonationAmount: number,
     campaignGoal: number,
     conversionQuota: number,
     singletoneRegistry: string,
     incentiveModel: number
     */
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
                    link: {
                        name: 'Call',
                        address: this.base.twoKeyCall.address,
                    },
                });


            } catch (e) {
                reject(e);
            }
        })
    }


}