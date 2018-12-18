import {ICreateOpts, IERC20, IOffchainData, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {
    IAcquisitionCampaign,
    IAcquisitionCampaignMeta,
    IJoinLinkOpts,
    IPublicLinkKey,
    IPublicLinkOpts,
    IReferrerSummary,
    ITokenAmount,
    ITwoKeyAcquisitionCampaign,
} from './interfaces';

import {BigNumber} from 'bignumber.js';
import contractsMeta, {default as contracts} from '../contracts';
import {promisify} from '../utils';
import Sign from '../utils/sign';

/**
 *
 * @param {number[]} cuts
 * @param {number} maxPi
 * @returns {number}
 */
function calcFromCuts(cuts: number[], maxPi: number) {
    let referrerRewardPercent: number = maxPi;
    // we have all the cuts up to us. calculate our maximal bounty
    for (let i = 0; i < cuts.length; i++) {
        let cut = cuts[i];

        // calculate bounty after taking the part for the i-th influencer
        if ((0 < cut) && (cut <= 101)) {
            cut--;
            referrerRewardPercent *= (100. - cut) / 100.
        } else {  // cut = 0 or 255 inidicate equal divistion down stream
            let n = cuts.length - i + 1; // how many influencers including us will split the bounty
            referrerRewardPercent *= (n - 1.) / n
        }
    }
    return referrerRewardPercent;
}

/**
 *
 * @returns {{private_key: string; public_address: string}}
 */
function generatePublicMeta(): { private_key: string, public_address: string } {
    let pk = Sign.generatePrivateKey();
    let public_address = Sign.privateToPublic(pk);
    const private_key = pk.toString('hex');
    return {private_key, public_address};
}

export default class AcquisitionCampaign implements ITwoKeyAcquisitionCampaign {
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
     *
     * @param {IAcquisitionCampaign} data
     * @param {string} from
     * @returns {Promise<number>}
     */
    public estimateCreation(data: IAcquisitionCampaign, from: string): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const {public_address} = generatePublicMeta();
                const predeployGas = await this.helpers._estimateSubcontractGas(contractsMeta.TwoKeyConversionHandler, from,
                    [
                        data.tokenDistributionDate,
                        data.maxDistributionDateShiftInDays,
                        data.bonusTokensVestingMonths,
                        data.bonusTokensVestingStartShiftInDaysFromDistributionDate,
                    ]);
                const campaignGas = await this.helpers._estimateSubcontractGas(contractsMeta.TwoKeyAcquisitionCampaignERC20, from, [
                    this.helpers._getContractDeployedAddress('TwoKeyEventSource'),
                    // Fake WhiteListInfluence address
                    `0x${public_address}`,
                    // Fake WhiteListConverter address
                    data.moderator || from,
                    data.assetContractERC20,
                    data.campaignStartTime,
                    data.campaignEndTime,
                    data.expiryConversion,
                    data.moderatorFeePercentageWei,
                    data.maxReferralRewardPercentWei,
                    data.maxConverterBonusPercentWei,
                    data.pricePerUnitInETHWei,
                    data.minContributionETHWei,
                    data.maxContributionETHWei,
                    data.referrerQuota || 5,
                ]);
                this.base._log('TwoKeyAcquisitionCampaignERC20 gas required', campaignGas);
                const totalGas = predeployGas + campaignGas;
                resolve(totalGas);
            } catch (err) {
                reject(err);
            }
        });
    }

    /**
     *
     * @param {IAcquisitionCampaign} data
     * @param {string} from
     * @param {ICreateCampaignProgress} progressCallback
     * @param {number} gasPrice
     * @param {number} interval
     * @param {number} timeout
     * @returns {Promise<IAcquisitionCampaignMeta>}
     */
    public create(data: IAcquisitionCampaign, from: string, {progressCallback, gasPrice, interval, timeout = 60000}: ICreateOpts = {}): Promise<IAcquisitionCampaignMeta> {
        return new Promise(async (resolve, reject) => {
            try {
                let txHash: string;
                const symbol = await this.erc20.getERC20Symbol(data.assetContractERC20);
                if (!symbol) {
                    reject('Invalid ERC20 address');
                    return;
                }
                let conversionHandlerAddress = data.conversionHandlerAddress;
                if (!conversionHandlerAddress) {
                    this.base._log([data.tokenDistributionDate, data.maxDistributionDateShiftInDays, data.bonusTokensVestingMonths, data.bonusTokensVestingStartShiftInDaysFromDistributionDate], gasPrice);
                    txHash = await this.helpers._createContract(contractsMeta.TwoKeyConversionHandler, from, {
                        gasPrice,
                        params: [data.tokenDistributionDate, data.maxDistributionDateShiftInDays, data.bonusTokensVestingMonths, data.bonusTokensVestingStartShiftInDaysFromDistributionDate],
                        progressCallback
                    });
                    const predeployReceipt = await this.utils.getTransactionReceiptMined(txHash, {
                        web3: this.base.web3,
                        interval,
                        timeout
                    });
                    if (predeployReceipt.status !== '0x1') {
                        reject(predeployReceipt);
                        return;
                    }
                    conversionHandlerAddress = predeployReceipt && predeployReceipt.contractAddress;
                    if (progressCallback) {
                        progressCallback('TwoKeyConversionHandler', true, conversionHandlerAddress);
                    }
                }

                txHash = await this.helpers._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20, from, {
                    gasPrice,
                    params: [
                        this.base.twoKeyEventSource.address,
                        // proxyInfo.TwoKeyEventSource.Proxy,
                        // this.helpers._getContractDeployedAddress('TwoKeyEventSource'),
                        conversionHandlerAddress,
                        data.moderator || from,
                        data.assetContractERC20,
                        [data.campaignStartTime,
                        data.campaignEndTime,
                        data.expiryConversion,
                        data.moderatorFeePercentageWei,
                        data.maxReferralRewardPercentWei,
                        data.maxConverterBonusPercentWei,
                        data.pricePerUnitInETHWei,
                        data.minContributionETHWei,
                        data.maxContributionETHWei,
                        data.referrerQuota || 5],
                        data.currency,
                        this.base.twoKeyExchangeContract.address,
                        this.base.twoKeyUpgradableExchange.address
                    ],
                    progressCallback,
                    link: {
                        name: 'Call',
                        address: this.base.twoKeyCall.address,
                    },
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
                    progressCallback('TwoKeyAcquisitionCampaignERC20', true, campaignAddress);
                }
                console.log('Campaign created', campaignAddress);
                const campaignPublicLinkKey = await this.join(campaignAddress, from, {gasPrice, progressCallback});
                if (progressCallback) {
                    progressCallback('SetPublicLinkKey', true, campaignPublicLinkKey);
                }
                resolve({
                    contractor: from,
                    campaignAddress,
                    conversionHandlerAddress,
                    campaignPublicLinkKey,
                });
            } catch (err) {
                reject(err);
            }
        });
    }

    /**
     *
     * @param {string} campaignAddress
     * @param {string} from
     * @returns {Promise<string>}
     */
    public addTwoKeyAcquisitionCampaignToBeEligibleToEmitEvents(campaignAddress: string, from: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const twoKeyAdminInstance = await this.helpers._getTwoKeyAdminInstance(contractsMeta.TwoKeyAdmin.networks[this.base.networks.mainNetId].address);
                const txHash: string = await promisify(twoKeyAdminInstance.twoKeyEventSourceAddAuthorizedContracts, [campaignAddress, {from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
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
                const nonce = await this.helpers._getNonce(from);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const txHash: string = await promisify(campaignInstance.updateOrSetIpfsHashPublicMeta, [hash, {
                    from,
                    gasPrice,
                    nonce,
                }]);
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
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const isAddressJoined = await this.isAddressJoined(campaignInstance, from);
                const ipfsHash = await promisify(campaignInstance.publicMetaHash, []);
                const meta = JSON.parse((await promisify(this.base.ipfs.cat, [ipfsHash])).toString());
                resolve({meta, isAddressJoined});
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param {string} hash
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getCampaignFromLink(hash: string, from?: string): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const {campaign} = await this.utils.getOffchainDataFromIPFSHash(hash);
                await this.visit(campaign, hash);
                const campaignMeta = await this.getPublicMeta({campaign, from});
                resolve(campaignMeta);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<number | string | BigNumber>}
     */
    public getInventoryBalance(campaign: any, from: string): Promise<number | string | BigNumber> {
        return new Promise<number>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const balance = await promisify(campaignInstance.getInventoryBalance, [{from}]);
                resolve(balance);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<number | string | BigNumber>}
     */
    public async checkInventoryBalance(campaign: any, from: string): Promise<number | string | BigNumber> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);

            const balance = await this.erc20.getERC20Balance(this.base.twoKeyEconomy.address, campaignInstance.address);
            return Promise.resolve(balance);
        } catch (err) {
            Promise.reject(err);
        }
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<number>}
     */
    public async getReferrerCut(campaign: any, from: string): Promise<number> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            const cut = (await promisify(campaignInstance.getReferrerCut, [{from}])).toNumber() + 1;
            return Promise.resolve(cut);
        } catch (e) {
            Promise.reject(e);
        }
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @param {string} referralLink
     * @returns {Promise<number>}
     */
    public getEstimatedMaximumReferralReward(campaign: any, from: string, referralLink: string): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                if (!referralLink) {
                    const cut = await this.getReferrerCut(campaign, from);
                    resolve(cut);
                } else {
                    const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                    const contractorAddress = await promisify(campaignInstance.contractor, []);
                    const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    const contractConstants = (await promisify(campaignInstance.getConstantInfo, []));
                    // const decimals = contractConstants[3].toNumber();
                    // this.base._log('Decimals', decimals);
                    this.base._log('getEstimatedMaximumReferralReward', f_address, contractorAddress);
                    // const maxReferralRewardPercent = new BigNumber(contractConstants[1]).div(10 ** decimals).toNumber();
                    const maxReferralRewardPercent = contractConstants[1].toNumber();
                    this.base._log('maxReferralRewardPercent', maxReferralRewardPercent)
                    if (f_address === contractorAddress) {
                        resolve(maxReferralRewardPercent);
                        return;
                    }
                    const firstAddressInChain = p_message ? `0x${p_message.substring(2, 42)}` : f_address;
                    this.base._log('RefCHAIN', contractorAddress, f_address, firstAddressInChain);
                    let cuts: number[];
                    const firstPublicLink = await promisify(campaignInstance.publicLinkKey, [firstAddressInChain]);
                    if (firstAddressInChain === contractorAddress) {
                        this.base._log('First public Link', firstPublicLink);
                        cuts = Sign.validate_join(firstPublicLink, f_address, f_secret, p_message);
                    } else {
                        cuts = (await promisify(campaignInstance.getReferrerCuts, [firstAddressInChain])).map(cut => cut.toNumber());
                        cuts = cuts.concat(Sign.validate_join(firstPublicLink, f_address, f_secret, p_message));
                    }
                    this.base._log('CUTS', cuts, maxReferralRewardPercent);
                    const estimatedMaxReferrerRewardPercent = calcFromCuts(cuts, maxReferralRewardPercent);
                    resolve(estimatedMaxReferrerRewardPercent);
                }
            } catch (e) {
                reject(e);
            }
        });
    }

    /* LINKS */

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
                const sig = Sign.free_take(this.base.plasmaAddress, f_address, f_secret, p_message);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaignAddress);
                const contractor = await promisify(campaignInstance.contractor, []);
                const txHash: string = await promisify(this.base.twoKeyPlasmaEvents.visited, [
                    campaignAddress,
                    contractor,
                    sig,
                    {from: this.base.plasmaAddress, gasPrice: 0}
                ]);
                // await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.plasmaWeb3});
                resolve(txHash);
            } catch (e) {
                reject(e);
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
     * @returns {Promise<IPublicLinkKey>}
     */
    public setPublicLinkKey(campaign: any, from: string, publicLink: string, {cut, gasPrice = this.base._getGasPrice(), progressCallback}: IPublicLinkOpts = {}): Promise<IPublicLinkKey> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const nonce = await this.helpers._getNonce(from);
                const contractor = await promisify(campaignInstance.contractor, [{from, nonce}]);
                // this.base._log('SETPUBLICLINK CONTRACTOR', contractor, publicLink);
                const mainTxHash = await promisify(campaignInstance.setPublicLinkKey, [publicLink, {
                    from,
                    gasPrice,
                }]);
                if (progressCallback) {
                    progressCallback('setPublicLinkKey', false, mainTxHash);
                }
                let plasmaTxHash;
                try {
                    plasmaTxHash = await promisify(this.base.twoKeyPlasmaEvents.setPublicLinkKey, [campaignInstance.address,
                        contractor, from, publicLink, {from: this.base.plasmaAddress, gasPrice: 0}
                    ]);
                    if (progressCallback) {
                        progressCallback('TwoKeyPlasmaEvents.setPublicLinkKey', false, plasmaTxHash);
                    }    
                } catch (plasmaErr) {
                    this.base._log('Plasma error:', plasmaErr);
                }
                const promises = [];
                promises.push(this.utils.getTransactionReceiptMined(mainTxHash));
                if (plasmaTxHash) {
                    promises.push(this.utils.getTransactionReceiptMined(plasmaTxHash, {web3: this.base.plasmaWeb3}))
                }
                await Promise.all(promises);
                if (promises.length > 1) {
                    if (progressCallback) {
                        progressCallback('TwoKeyPlasmaEvents.setPublicLinkKey', true, plasmaTxHash);
                    }    
                }
                if (progressCallback) {
                    progressCallback('setPublicLinkKey', true, mainTxHash);
                }
                if (cut > -1) {
                    await promisify(campaignInstance.setCut, [cut - 1, {from}]);
                }
                resolve({publicLink, contractor});
            } catch (err) {
                reject(err);
            }
        });
    }

    // Get Public Link
    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<string>}
     */
    public async getPublicLinkKey(campaign: any, from: string): Promise<string> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            console.log(campaignInstance.publicLinkKey);
            const publicLink = await promisify(campaignInstance.publicLinkKey, [from]);
            return Promise.resolve(publicLink);
        } catch (e) {
            Promise.reject(e)
        }
    }

    // Join Offchain
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
     * @returns {Promise<string>}
     */
    public join(campaign: any, from: string, {cut, gasPrice = this.base._getGasPrice(), referralLink, cutSign, voting, daoContract, progressCallback}: IJoinLinkOpts = {}): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignAddress = typeof (campaign) === 'string' ? campaign
                    : (await this.helpers._getAcquisitionCampaignInstance(campaign)).address;

                // if (from !== this.base.plasmaAddress) {
                const sig = await Sign.sign_plasma2eteherum(this.base.plasmaAddress, from, this.base.web3);
                this.base._log('Signature', sig);
                this.base._log(campaignAddress, from, this.base.plasmaAddress, cut);
                let txHash: string;
                try {
                    txHash = await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum, [sig, {
                        from: this.base.plasmaAddress,
                        gasPrice: 0
                    }]);
                    await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.plasmaWeb3, timeout: 300000});
                    const stored_ethereum_address = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [this.base.plasmaAddress]);
                    if (stored_ethereum_address !== from) {
                        reject(stored_ethereum_address + ' != ' + from)
                    }
                } catch (plasmaErr) {
                    this.base._log('Plasma Error:', plasmaErr);
                }

                const private_key = this.base.web3.sha3(sig).slice(2, 2 + 32 * 2);
                const public_address = Sign.privateToPublic(Buffer.from(private_key, 'hex'));

                let new_message;
                let contractor;
                let dao;
                if (referralLink) {
                    const {f_address, f_secret, p_message, contractor: campaignContractor, dao: daoAddress} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    contractor = campaignContractor;
                    dao = daoAddress;
                    // this.base._log('New link for', from, f_address, f_secret, p_message);
                    // this.base._log('P_MESSAGE', p_message);
                    // TODO: Andrii in AcquisitionCampaign this method was with (cut + 1)
                    new_message = Sign.free_join(from, public_address, f_address, f_secret, p_message, voting ? cut : cut + 1, cutSign);
                } else {
                    const {contractor: campaignContractor} = await this.setPublicLinkKey(campaign, from, `0x${public_address}`, {
                        cut,
                        gasPrice,
                        progressCallback,
                    });
                    dao = voting ? daoContract : undefined;
                    contractor = campaignContractor;
                }
                const linkObject: IOffchainData = {
                    campaign: campaignAddress,
                    contractor,
                    f_address: from,
                    f_secret: private_key,
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

    // ShortUrl
    /**
     *
     * @param campaign
     * @param {string} from
     * @param {string} referralLink
     * @param {number} cut
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public joinAndSetPublicLinkWithCut(campaign: any, from: string, referralLink: string, {cut, gasPrice = this.base._getGasPrice()}: IPublicLinkOpts = {}): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
            if (!f_address || !f_secret) {
                reject('Broken Link');
            }
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                let arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [from])).toString());
                const {public_address, private_key} = generatePublicMeta();

                if (!arcBalance) {
                    this.base._log('No Arcs', arcBalance, 'Call Free Join Take');
                    const signature = Sign.free_join_take(from, public_address, f_address, f_secret, p_message, cut + 1);
                    const nonce = await this.helpers._getNonce(from);
                    const txHash: string = await promisify(campaignInstance.distributeArcsBasedOnSignature, [signature, {
                        from,
                        gasPrice,
                        nonce,
                    }]);
                    this.base._log('setPubLinkWithCut', txHash);
                    await this.utils.getTransactionReceiptMined(txHash);
                    arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [from])).toString());
                }
                if (arcBalance) {
                    const link = await this.utils.ipfsAdd({f_address: from, f_secret: private_key});
                    resolve(link);
                } else {
                    reject(new Error('Link is broken!'));
                }
            } catch (err) {
                reject(err);
            }
        });
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getBalanceOfArcs(campaign: any, from: string): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const balance = (await promisify(campaignInstance.balanceOf, [from])).toNumber();
                resolve(balance);
            } catch (e) {
                reject(e);
            }
        });
    }

    /* PARTICIPATE */
    /**
     *
     * @param campaign
     * @param {string | number | BigNumber} value
     * @returns {Promise<ITokenAmount>}
     */
    public getEstimatedTokenAmount(campaign: any, value: string | number | BigNumber): Promise<ITokenAmount> {
        return new Promise<ITokenAmount>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const constants = await promisify(campaignInstance.getConstantInfo, []);
                let [baseTokens, bonusTokens] = await promisify(campaignInstance.getEstimatedTokenAmount, [value]);
                baseTokens = this.utils.fromWei(baseTokens, constants[3]);
                baseTokens = BigNumber.isBigNumber(baseTokens) ? baseTokens.toNumber() : parseFloat(baseTokens);
                bonusTokens = this.utils.fromWei(bonusTokens, constants[3]);
                bonusTokens = BigNumber.isBigNumber(bonusTokens) ? bonusTokens.toNumber() : parseFloat(bonusTokens);
                resolve({
                    baseTokens,
                    bonusTokens,
                    totalTokens: baseTokens + bonusTokens,
                });
            } catch (e) {
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
     * @returns {Promise<string>}
     */
    public joinAndConvert(campaign: any, value: string | number | BigNumber, publicLink: string, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(publicLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);

                const prevChain = await promisify(campaignInstance.received_from, [from]);
                const nonce = await this.helpers._getNonce(from);
                if (!parseInt(prevChain, 16)) {
                    this.base._log('No ARCS call Free Join Take');
                    // const newPublicLink = await this.join(campaignInstance, from, { referralLink: publicLink, cut })
                    const { public_address } = generatePublicMeta();
                    const signature = Sign.free_join_take(from, public_address, f_address, f_secret, p_message);
                    // TODO: Nikola try to comment two lines before and uncomment next line 
                    // const signature = Sign.free_take(from, f_address, f_secret, p_message);
                    const txHash: string = await promisify(campaignInstance.joinAndConvert, [signature, {
                        from,
                        gasPrice,
                        value,
                        nonce,
                    }]);
                    resolve(txHash);
                } else {
                    this.base._log('Previous referrer', prevChain, value);
                    const txHash: string = await promisify(campaignInstance.convert, [{
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

    // Send ARCS to other account
    /**
     *
     * @param campaign
     * @param {string} from
     * @param {string} referralLink
     * @param {string} recipient
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public joinAndShareARC(campaign: any, from: string, referralLink: string, recipient: string, {gasPrice = this.base._getGasPrice()}: IPublicLinkOpts = {}): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [from])).toString());
                const prevChain = await promisify(campaignInstance.received_from, [recipient]);
                if (parseInt(prevChain, 16)) {
                    reject(new Error('User already in chain'));
                }
                const nonce = await this.helpers._getNonce(from);
                if (!arcBalance) {
                    const {public_address} = generatePublicMeta();
                    this.base._log('joinAndShareARC call Free Join Take');
                    const signature = Sign.free_join_take(from, public_address, f_address, f_secret, p_message);
                    this.base._log(signature, recipient);
                    const txHash: string = await promisify(campaignInstance.joinAndShareARC, [signature, recipient, {
                        from,
                        gasPrice,
                        nonce,
                    }]);
                    resolve(txHash);
                } else {
                    const txHash: string = await promisify(campaignInstance.transfer, [recipient, 1, {
                        from,
                        gasPrice,
                        nonce,
                    }]);
                    resolve(txHash);
                }
            } catch (e) {
                reject(e);
            }
        });
    }

    /* HELPERS */
    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<boolean>}
     */
    public isAddressJoined(campaign: any, from: string): Promise<boolean> {
        return new Promise<boolean>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                resolve(await promisify(campaignInstance.getAddressJoinedStatus, [{from}]));
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
    public getConverterConversion(campaign: any, from: string): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.conversionHandler, [{from}]);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                const conversion = await promisify(conversionHandlerInstance.conversions, [from]);
                resolve(conversion);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @returns {Promise<string>}
     */
    public getTwoKeyConversionHandlerAddress(campaign: any): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.conversionHandler, []);
                resolve(conversionHandler);
            } catch (e) {
                reject(e);
            }
        })
    }

    // public getAssetContractData(campaign: any, from: string): Promise<any> {
    //     return new Promise(async (resolve, reject) => {
    //         try {
    //             const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
    //             const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
    //             // const assetContractData = await promisify(conversionHandlerInstance.getContractor, [{ from }]);
    //             // const assetContractData = await promisify(conversionHandlerInstance.getAssetContractData, []);
    //             resolve(assetContractData)
    //         } catch (e) {
    //             reject(e);
    //         }
    //     })
    // }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getAllPendingConverters(campaign: any, from: string): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                console.log('getAllPendingConverters', campaign, from);

                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const pendingConverters = await promisify(conversionHandlerInstance.getAllPendingConverters, [{from}]);
                resolve(pendingConverters);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} converter
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public approveConverter(campaign: any, converter: string, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash: string = await promisify(conversionHandlerInstance.approveConverter, [converter, {
                    from,
                    gasPrice,
                    nonce
                }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} converter
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public rejectConverter(campaign: any, converter: string, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash: string = await promisify(conversionHandlerInstance.rejectConverter, [converter, {
                    from,
                    gasPrice,
                    nonce
                }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public cancelConverter(campaign: any, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash: string = await promisify(conversionHandlerInstance.cancelConverter, [{
                    from,
                    gasPrice,
                    nonce
                }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getApprovedConverters(campaign: any, from: string): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const approvedConverters = await promisify(conversionHandlerInstance.getAllApprovedConverters, [{from}]);
                resolve(approvedConverters);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getAllRejectedConverters(campaign: any, from: string): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const rejectedConverters = await promisify(conversionHandlerInstance.getAllRejectedConverters, [{from}]);
                resolve(rejectedConverters);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} converter
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public executeConversion(campaign: any, converter: string, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const nonce = await this.helpers._getNonce(from);
                const txHash: string = await promisify(conversionHandlerInstance.executeConversion, [converter, {
                    from,
                    gasPrice,
                    nonce
                }]);
                this.base._log(txHash);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} converter
     * @param {string} from
     * @returns {Promise<string[]>}
     */
    public getLockupContractsForConverter(campaign: any, converter: string, from: string): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const lockupContractAddresses = await promisify(conversionHandlerInstance.getLockupContractsForConverter, [converter, {from}]);
                resolve(lockupContractAddresses);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param campaign
     * @param {number} amount
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public addFungibleAssetsToInventoryOfCampaign(campaign: any, amount: number, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const nonce = await this.helpers._getNonce(from);
                const txHash: string = await promisify(campaignInstance.addUnitsToInventory, [amount, {
                    from,
                    gasPrice,
                    nonce
                }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public cancel(campaign: any, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const txHash: string = await promisify(campaignInstance.cancel, [{from, gasPrice, nonce}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<boolean>}
     */
    public isAddressContractor(campaign: any, from: string): Promise<boolean> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const result: string = await promisify(campaignInstance.contractor, [{from}]);
                resolve(result === from);
            } catch (e) {
                reject(e);
            }
        })
    }




    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getAmountOfEthAddressSentToAcquisition(campaign: any, from: string): Promise<number> {
        return new Promise<number>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const value: number = await promisify(campaignInstance.getAmountAddressSent, [from]);
                resolve(value);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public contractorWithdraw(campaign: any, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const txHash: string = await promisify(campaignInstance.withdrawContractor, [{
                    from,
                    gasPrice,
                    nonce
                }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getContractorBalance(campaign: any, from: string): Promise<number> {
        return new Promise<number>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const balanceinWei = await promisify(campaignInstance.getContractorBalance, [{from}]);
                resolve(balanceinWei);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getModeratorBalance(campaign: any, from: string): Promise<number> {
        return new Promise<number>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                let [moderatorBalance, moderatorTotalEarnings] = await promisify(campaignInstance.getModeratorBalanceAndTotalEarnings, [{from}]);
                resolve(moderatorBalance);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     *
     * @param campaign
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<any>}
     */
    public moderatorAndReferrerWithdraw(campaign: any, from: string, gasPrice: number = this.base._getGasPrice()) : Promise<any> {
        return new Promise<any>(async(resolve,reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                console.log('Upgradable exchange address: ' + this.base.twoKeyUpgradableExchange.address);
                const balance = await this.erc20.getERC20Balance(this.base.twoKeyEconomy.address, this.base.twoKeyUpgradableExchange.address);
                console.log("Balance of 2keys on upgradable exchange is: " + balance);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const txHash: string = await promisify(campaignInstance.withdrawModeratorOrReferrer,[
                    {
                        from,
                        gasPrice,
                        nonce
                    }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<string>}
     */
    public getModeratorAddress(campaign: any, from: string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
           try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const moderator: string = await promisify(campaignInstance.moderator,[{from}]);
                resolve(moderator);
           } catch (e) {
               reject(e);
           }
        });
    }


    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<string>}
     */
    public getAcquisitionCampaignCurrency(campaign: any, from: string) : Promise<string> {
        return new Promise<string>(async(resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const currency: string = await promisify(campaignInstance.currency,[{from}]);
                resolve(currency);
            } catch (e) {
                reject(e);
            }
        });
    }

    /**
     *
     * @param campaign
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getModeratorTotalEarnings(campaign:any, from:string) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                let [moderatorBalance,moderatorBalanceTotal] = await promisify(campaignInstance.getModeratorBalanceAndTotalEarnings,[{from}]);
                resolve(moderatorBalanceTotal);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} referrer
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getReferrerBalanceAndTotalEarningsAndNumberOfConversions(campaign:any, referrer: string, from: string) : Promise<IReferrerSummary> {
        return new Promise<any>(async(resolve,reject) => {
           try {
               const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
               let [referrerBalanceAvailable, referrerTotalEarnings, referrerInCountOfConversions] =
                   await promisify(campaignInstance.getReferrerBalanceAndTotalEarningsAndNumberOfConversions,[referrer, {from}]);
               const obj = {
                   balanceAvailable: parseFloat(this.utils.fromWei(referrerBalanceAvailable, 'ether').toString()),
                   totalEarnings: parseFloat(this.utils.fromWei(referrerTotalEarnings, 'ether').toString()),
                   numberOfConversionsParticipatedIn : parseFloat(this.utils.fromWei(referrerInCountOfConversions, 'ether').toString()),
                   campaignAddress: campaignInstance.address,
               };
               resolve(obj)
           } catch (e) {
               reject(e);
           }
        });
    }

}