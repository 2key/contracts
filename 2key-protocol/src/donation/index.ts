import {ICampaignData, ICreateCampaign, IDonation, IDonationCampaign, InvoiceERC20} from "./interfaces";
import {ICreateOpts, IERC20, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from "../interfaces";
import {ISign} from "../sign/interface";
import donationContracts, {default as donation} from '../contracts/donation';
import { promisify } from '../utils/promisify';
import acquisitionContracts from "../contracts/acquisition";
import {IConvertOpts, IJoinLinkOpts, IOffchainData, IPublicLinkKey, IPublicLinkOpts} from "../acquisition/interfaces";
import {BigNumber} from "bignumber.js";


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
        if (skipCache) {
            const campaignInstance = await this.helpers._createAndValidate(donationContracts.TwoKeyDonationCampaign.abi, campaign);
            return campaignInstance;
        }
        if (this.DonationCampaign && this.DonationCampaign.address === address) {
            return this.DonationCampaign;
        }
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
    public create(data: ICreateCampaign, from: string, {progressCallback, gasPrice, interval, timeout = 60000}: ICreateOpts = {}): Promise<any> {
        return new Promise<any>(async(resolve,reject) => {
            try {
                let txHash: string = await this.helpers._createContract(donationContracts.TwoKeyDonationCampaign, from, {
                    gasPrice,
                    params: [
                        data.moderator,
                        data.campaignName,
                        data.invoiceToken.tokenName,
                        data.invoiceToken.tokenSymbol,
                        [
                            this.utils.toWei(data.maxReferralRewardPercent),
                            data.campaignStartTime,
                            data.campaignEndTime,
                            this.utils.toWei(data.minDonationAmount),
                            this.utils.toWei(data.maxDonationAmount),
                            this.utils.toWei(data.campaignGoal),
                            data.conversionQuota
                        ],
                        data.shouldConvertToRefer,
                        data.isKYCRequired,
                        data.acceptsFiat,
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

                txHash = await promisify(this.base.twoKeyCampaignValidator.validateDonationCampaign,[campaignAddress,this.nonSingletonsHash,{from}]);
                if (progressCallback) {
                    progressCallback('ValidateCampaign', false, txHash);
                }
                await this.utils.getTransactionReceiptMined(txHash, {
                    web3: this.base.web3,
                    interval,
                    timeout
                });
                if (progressCallback) {
                    progressCallback('ValidateCampaign', true, txHash);
                }
                resolve({
                    contractor: from,
                    campaignAddress,
                    campaignPublicLinkKey,
                    ephemeralContractsVersion: this.nonSingletonsHash,
                });
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
                    campaign_web3_address: campaignAddress,
                    contractor,
                    f_address: plasmaAddress,
                    f_secret: private_key,
                    ephemeralContractsVersion: this.nonSingletonsHash,
                    campaign_type: 'donation',
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

    /**
     *
     * @param campaign
     * @param {string} hash
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public updateOrSetIpfsHashPublicMeta(campaign: any, hash: string, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign);
                const nonce = await this.helpers._getNonce(from);
                const txHash: string = await promisify(campaignInstance.updateOrSetPublicMetaHash, [hash, {
                    from,
                    gasPrice,
                    nonce,
                }]);
                console.log('txHash', txHash);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getPublicMeta(campaign: any, from?: string): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign);
                const ipfsHash = await promisify(campaignInstance.publicMetaHash, []);
                const meta = JSON.parse((await promisify(this.base.ipfsR.cat, [ipfsHash])).toString());
                resolve({meta});
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     * Only contractor or moderator can get it
     * @param campaign
     * @param {string} from
     * @returns {Promise<string>}
     */
    public getPrivateMetaHash(campaign: any, from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const donationCampaignInstance = await this._getCampaignInstance(campaign);
                let ipfsHash: string = await promisify(donationCampaignInstance.privateMetaHash,[{from}]);


                let privateHashEncrypted = await promisify(this.base.ipfsR.cat, [ipfsHash]);
                privateHashEncrypted = privateHashEncrypted.toString();


                let privateMetaHashDecrypted = await this.sign.decrypt(this.base.web3,from,privateHashEncrypted,{plasma : false});
                resolve(privateMetaHashDecrypted.slice(2)); //remove 0x from the beginning
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Only contractor or moderator can set it
     * @param campaign
     * @param {string} privateMetaHash
     * @param {string} from
     * @returns {Promise<string>}
     */
    public setPrivateMetaHash(campaign: any, data: any, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                //Convert data to string
                const dataString = typeof data === 'string' ? data : JSON.stringify(data);

                //Encrypt the string
                let encryptedString = await this.sign.encrypt(this.base.web3, from, dataString, {plasma:false});

                const hash = await this.utils.ipfsAdd(encryptedString);

                const donationCampaignInstance = await this._getCampaignInstance(campaign);
                let txHash: string = await promisify(donationCampaignInstance.updateOrSetPrivateMetaHash,[hash,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     * Get the public link key for message sender
     * @param campaign
     * @param {string} from
     * @returns {Promise<string>}
     */
    public getPublicLinkKey(campaign: any, from: string): Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign);
                const publicLink = await promisify(campaignInstance.publicLinkKeyOf, [from]);
                resolve(publicLink);
            } catch (e) {
                reject(e)
            }
        })
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
     * @param {string} referralLink
     * @returns {Promise<string>}
     */
    public visit(campaignAddress: string, referralLink: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                const plasmaAddress = this.base.plasmaAddress;
                const sig = this.sign.free_take(plasmaAddress, f_address, f_secret, p_message);
                const campaignInstance = await this._getCampaignInstance(campaignAddress);
                const contractor = await promisify(campaignInstance.contractor, []);
                const joinedFrom = await promisify(this.base.twoKeyPlasmaEvents.joined_from, [campaignInstance.address, contractor, plasmaAddress]);
                const txHash: string = await promisify(this.base.twoKeyPlasmaEvents.visited, [
                    campaignInstance.address,
                    contractor,
                    sig,
                    {from: plasmaAddress, gasPrice: 0}
                ]);
                if (!parseInt(joinedFrom, 16)) {
                    await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.plasmaWeb3});
                    const note = await this.sign.encrypt(this.base.plasmaWeb3, plasmaAddress, f_secret, {plasma: true});
                    const noteTxHash = await promisify(this.base.twoKeyPlasmaEvents.setNoteByUser, [campaignInstance.address, note, {from: plasmaAddress}]);
                }
                resolve(txHash);
            } catch (e) {
                console.error(e);
                reject(e);
            }
        });
    }

    /**
     *
     * @param campaign
     * @param {string | number | BigNumber} value
     * @param {string} publicLink
     * @param {string} from
     * @param {number} gasPrice
     * @param {boolean} isConverterAnonymous
     * @returns {Promise<string>}
     */
    public joinAndConvert(campaign: any, value: string | number | BigNumber, publicLink: string, from: string, {gasPrice = this.base._getGasPrice(), isConverterAnonymous}: IConvertOpts = {}): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(publicLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const campaignInstance = await this._getCampaignInstance(campaign);
                const prevChain = await promisify(campaignInstance.getReceivedFrom, [from]);
                const nonce = await this.helpers._getNonce(from);
                let txHash;
                if (!parseInt(prevChain, 16)) {
                    const plasmaAddress = this.base.plasmaAddress;
                    const signature = this.sign.free_take(plasmaAddress, f_address, f_secret, p_message);

                    const cuts = this.sign.validate_join(null, null, null, signature, plasmaAddress);

                    txHash = await promisify(campaignInstance.joinAndDonate, [signature, {
                        from,
                        gasPrice,
                        value,
                        nonce,
                    }]);

                    try {
                        const contractor = await promisify(campaignInstance.contractor, []);
                        await this.helpers._awaitPlasmaMethod(promisify(this.base.twoKeyPlasmaEvents.joinCampaign, [campaignInstance.address, contractor, signature, { from: plasmaAddress, gasPrice: 0 }]));
                    } catch (e) {
                        console.log('Plasma joinCampaign error', e);
                    }
                    resolve(txHash);
                } else {
                    const txHash: string = await promisify(campaignInstance.convert, [false,{
                        from,
                        gasPrice,
                        value,
                        nonce,
                    }]);
                    resolve(txHash);
                }
            } catch (e) {
                this.base._log('joinAndConvert ERROR', e.toString());
                this.base._log(e);
                reject(e);
            }
        });
    }


    /**
     *
     * @param {string} campaignAddress
     * @param {number} donationId
     * @param {string} from
     * @returns {Promise<IDonation>}
     */
    public getDonation(campaignAddress: string, donationId: number, from: string) : Promise<IDonation> {
        return new Promise<IDonation>(async(resolve,reject) => {
            try {
                let donationCampaignInstance = await this._getCampaignInstance(campaignAddress);
                let data = await promisify(donationCampaignInstance.getDonation,[donationId,{from}]);
                /**
                 donator: string,
                 donationAmount: number
                 donationTime: number,
                 bountyEthWei: number,
                 bounty2key: number
                 */

                let states = ["PENDING_APPROVAL", "APPROVED", "EXECUTED", "REJECTED", "CANCELLED_BY_CONVERTER"];

                let donator = data.slice(0,42);
                let donationAmount = parseInt(data.slice(42,42+64),16);
                let contractorProceeds = parseInt(data.slice(42+64,42+64+64),16);
                let donationTime = parseInt(data.slice(42+64+64,42+64+64+64),16);
                let bountyEthWei = parseInt(data.slice(42+64+64+64,42+64+64+64+64),16);
                let bounty2key = parseInt(data.slice(42+64+64+64+64,42+64+64+64+64+64), 16);
                let state = states[parseInt(data.slice(42+64+64+64+64+64),16)];

                let obj: IDonation = {
                    donator,
                    'donationAmount' : parseFloat(this.utils.fromWei(donationAmount,'ether').toString()),
                    'contractorProceeds' : parseFloat(this.utils.fromWei(contractorProceeds, 'ether').toString()),
                    donationTime,
                    'bountyEthWei' : parseFloat(this.utils.fromWei(bountyEthWei,'ether').toString()),
                    'bounty2key' : parseFloat(this.utils.fromWei(bounty2key,'ether').toString()),
                    state
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} campaignAddress
     * @param {string} converter
     * @param {string} from
     * @returns {Promise<string>}
     */
    public approveConverter(campaignAddress: string, converter: string, from:string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                let campaignInstance = await this._getCampaignInstance(campaignAddress);
                //Bear in mind this can only be done by Contractor
                let txHash = await promisify(campaignInstance.approveConverter,[converter,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param {string} campaignAddress
     * @param {string} converter
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getRefferrersToConverter(campaignAddress: string, converter: string, from: string) : Promise<string[]> {
        return new Promise<string[]>(async(resolve,reject) => {
            try {
                let campaignInstance = await this._getCampaignInstance(campaignAddress);
                let referrers = await promisify(campaignInstance.getReferrers,[converter,{from}]);
                let balances = [];
                for(let i=0; i<referrers.length; i++) {
                    let balance = await promisify(campaignInstance.getReferrerBalance,[referrers[i]]);
                    balances.push(parseFloat(this.utils.fromWei(balance,'ether').toString()))
                }
                console.log(balances);
                resolve(referrers);
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
    public getIncentiveModel(campaignAddress: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                let campaignInstance = await this._getCampaignInstance(campaignAddress);
                let models = ["NO_REWARDS","AVERAGE", "AVERAGE_LAST_3X", "POWER_LAW", "MANUAL"];
                let incentiveModel = await promisify(campaignInstance.getIncentiveModel,[]);
                resolve(models[incentiveModel]);
            } catch (e) {
                reject(e);
            }
        })
    }


}
