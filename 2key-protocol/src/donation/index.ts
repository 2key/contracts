import {ICampaignData, ICreateCampaign, IDonationCampaign, InvoiceERC20} from "./interfaces";
import {ICreateOpts, IERC20, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from "../interfaces";
import {ISign} from "../sign/interface";
import donationContracts, {default as donation} from '../contracts/donation';
import { promisify } from '../utils/promisify';
import acquisitionContracts from "../contracts/acquisition";
import {IJoinLinkOpts, IOffchainData, IPublicLinkKey, IPublicLinkOpts} from "../acquisition/interfaces";



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
                        data.maxReferralRewardPercent,
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

                const campaignPublicLinkKey = await this.join(campaignAddress, from, {gasPrice, progressCallback, interval, timeout});
                if (progressCallback) {
                    progressCallback('SetPublicLinkKey', true, campaignPublicLinkKey);
                }

                resolve(campaignAddress);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @param {number} cut
     * @param {number} gasPrice
     * @param {string} referralLink
     * @param {string} cutSign
     * @param {boolean} voting
     * @param {string} daoContract
     * @param {ICreateCampaignProgress} progressCallback
     * @param {number} interval
     * @param {number} timeout
     * @returns {Promise<string>}
     */
    public join(campaign: any, from: string, {
        cut,
        gasPrice = this.base._getGasPrice(),
        referralLink,
        cutSign,
        voting,
        daoContract,
        progressCallback,
        interval,
        timeout,
    }: IJoinLinkOpts = {}): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignAddress = typeof (campaign) === 'string' ? campaign
                    : (await this._getCampaignInstance(campaign)).address;
                const safeCut = this.sign.fixCut(cut);
                const i = 1;
                const plasmaAddress = this.base.plasmaAddress;
                const msg = `0xdeadbeef${campaignAddress.slice(2)}${plasmaAddress.slice(2)}${i.toString(16)}`;
                const signedMessage = await this.sign.sign_message(this.base.plasmaWeb3, msg, plasmaAddress, { plasma: true });
                const private_key = this.base.web3.sha3(signedMessage).slice(2, 2 + 32 * 2);
                const public_address = this.sign.privateToPublic(Buffer.from(private_key, 'hex'));
                this.base._log('Signature', signedMessage);
                this.base._log(campaignAddress, from, plasmaAddress, safeCut);
                let new_message;
                let contractor;
                let dao;
                if (referralLink) {
                    const {f_address, f_secret, p_message, contractor: campaignContractor, dao: daoAddress} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    contractor = campaignContractor;
                    dao = daoAddress;
                    try {
                        const campaignInstance = await this._getCampaignInstance(campaignAddress);
                        const contractorAddress = await promisify(campaignInstance.contractor, []);
                        const plasmaAddress = this.base.plasmaAddress;
                        const sig = this.sign.free_take(plasmaAddress, f_address, f_secret, p_message);
                        console.log('twoKeyPlasmaEvents.joinCampaign join', campaignInstance.address, contractorAddress, sig, plasmaAddress);
                        const txHash = await this.helpers._awaitPlasmaMethod(promisify(this.base.twoKeyPlasmaEvents.joinCampaign, [campaignInstance.address, contractorAddress, sig, { from: plasmaAddress, gasPrice: 0 }]));
                        await this.utils.getTransactionReceiptMined(txHash, { web3: this.base.plasmaWeb3 });
                    } catch (e) {
                        console.log('Plasma joinCampaign error', e);
                    }
                    new_message = this.sign.free_join(plasmaAddress, public_address, f_address, f_secret, p_message, safeCut, cutSign);
                } else {
                    const {contractor: campaignContractor} = await this.setPublicLinkKey(campaign, from, `0x${public_address}`, {
                        cut: safeCut,
                        gasPrice,
                        progressCallback,
                        interval,
                        timeout,
                    });
                    dao = voting ? daoContract : undefined;
                    contractor = campaignContractor;
                }
                const linkObject: IOffchainData = {
                    campaign: campaignAddress,
                    contractor,
                    f_address: plasmaAddress,
                    f_secret: private_key,
                    ephemeralContractsVersion: this.nonSingletonsHash,
                    dao,
                };
                if (new_message) {
                    linkObject.p_message = new_message;
                }
                const link = await this.utils.ipfsAdd(linkObject);
                resolve(link);
            } catch (err) {
                this.base._log('ERRORORRR', err, err.toString());
                reject(err);
            }
        });
    }

    // Set Public Link
    /**
     *
     * @param campaign
     * @param {string} from
     * @param {string} publicLink
     * @param {number} cut
     * @param {number} gasPrice
     * @param {ICreateCampaignProgress} progressCallback
     * @param {number} interval
     * @param {number} timeout
     * @returns {Promise<IPublicLinkKey>}
     */
    public setPublicLinkKey(campaign: any, from: string,  publicLink: string, {
        cut,
        gasPrice = this.base._getGasPrice(),
        progressCallback,
        interval,
        timeout,
    }: IPublicLinkOpts = {}): Promise<IPublicLinkKey> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign);
                const nonce = await this.helpers._getNonce(from);
                const contractor = await promisify(campaignInstance.contractor, [{from}]);
                const txHash = await promisify(campaignInstance.setPublicLinkKey, [
                    publicLink,
                    { from, nonce ,gasPrice }
                ]);

                let plasmaTxHash;
                try {

                    plasmaTxHash = await this.helpers._awaitPlasmaMethod(promisify(this.base.twoKeyPlasmaEvents.setPublicLinkKey, [
                        campaignInstance.address,
                        contractor,
                        publicLink,
                        {from: this.base.plasmaAddress}
                    ]));
                    if (progressCallback) {
                        progressCallback('Plasma.setPublicLinkKey', false, plasmaTxHash);
                    }
                } catch (e) {
                    this.base._log('Plasma setPublicLinkKey error', e);
                }

                const promises = [];
                promises.push(this.utils.getTransactionReceiptMined(txHash, { interval, timeout }));
                if (plasmaTxHash) {
                    promises.push(this.utils.getTransactionReceiptMined(plasmaTxHash, {web3: this.base.plasmaWeb3}));
                }

                await Promise.all(promises);

                if (progressCallback) {
                    if (plasmaTxHash) {
                        progressCallback('Plasma.setPublicLinkKey', true, publicLink);
                    }
                    progressCallback('setPublicLinkKey', true, publicLink);
                }
                resolve({publicLink, contractor});
            } catch (err) {
                reject(err);
            }
        });
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
                console.log(data.slice(66+64+64+64+64));
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