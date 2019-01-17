import {ICreateOpts, IERC20, IOffchainData, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {
    IAcquisitionCampaign,
    IAcquisitionCampaignMeta, IConstantsLogicHandler, IConversionObject, IConversionStats,
    IConvertOpts,
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
    let public_address = Sign.privateToPublic(Buffer.from(pk,'hex'));
    const private_key = pk;
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
                const predeployGasConversionHandler = await this.helpers._estimateSubcontractGas(contractsMeta.TwoKeyConversionHandler, from,
                    [
                        data.tokenDistributionDate,
                        data.maxDistributionDateShiftInDays,
                        data.bonusTokensVestingMonths,
                        data.bonusTokensVestingStartShiftInDaysFromDistributionDate,
                    ]);

                const predeployGasLogicHandler = await this.helpers._estimateSubcontractGas(contractsMeta.TwoKeyAcquisitionLogicHandler, from,
                    [
                        data.minContributionETHWei,
                        data.maxContributionETHWei,
                        data.pricePerUnitInETHWei,
                        data.campaignStartTime,
                        data.campaignEndTime,
                        data.maxConverterBonusPercentWei,
                        data.currency,
                        data.twoKeyExchangeContract,
                        data.assetContractERC20
                    ]);

                const campaignGas = await this.helpers._estimateSubcontractGas(contractsMeta.TwoKeyAcquisitionCampaignERC20, from, [
                    `0x${public_address}`,
                    this.helpers._getContractDeployedAddress('TwoKeyEventSource'),
                    // Fake WhiteListInfluence address
                    `0x${public_address}`,
                    // Fake WhiteListConverter address
                    data.moderator || from,
                    data.assetContractERC20,
                    data.expiryConversion,
                    data.moderatorFeePercentageWei,
                    data.maxReferralRewardPercentWei,
                    data.referrerQuota || 5,
                    `0x${public_address}`,
                ]);
                this.base._log('TwoKeyAcquisitionCampaignERC20 gas required', campaignGas);
                const totalGas = predeployGasConversionHandler + predeployGasLogicHandler + campaignGas;
                console.log('Gas to deploy Conversion handler:  ' + predeployGasConversionHandler);
                console.log('Gas to deploy Logic handler: ' + predeployGasLogicHandler);
                console.log('Gas to deploy Campaign: ' + campaignGas);
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
                /**
                 * Creating and deploying conversion handler contract
                 */
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
                /**
                 * Creating and deploying logic handler contract
                 */
                let twoKeyAcquisitionLogicHandlerAddress = data.twoKeyAcquisitionLogicHandler;
                if(!twoKeyAcquisitionLogicHandlerAddress) {
                    txHash = await this.helpers._createContract(contractsMeta.TwoKeyAcquisitionLogicHandler, from, {
                        gasPrice,
                        params: [data.minContributionETHWei, data.maxContributionETHWei,data.pricePerUnitInETHWei,
                            data.campaignStartTime, data.campaignEndTime, data.maxConverterBonusPercentWei,
                            data.currency, this.base.twoKeyExchangeContract.address, data.assetContractERC20],
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
                    twoKeyAcquisitionLogicHandlerAddress = predeployReceipt && predeployReceipt.contractAddress;
                    if (progressCallback) {
                        progressCallback('TwoKeyAcquisitionLogicHandler', true, twoKeyAcquisitionLogicHandlerAddress);
                    }

                }

                txHash = await this.helpers._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20, from, {
                    gasPrice,
                    params: [
                        twoKeyAcquisitionLogicHandlerAddress,
                        this.base.twoKeyEventSource.address,
                        // proxyInfo.TwoKeyEventSource.Proxy,
                        // this.helpers._getContractDeployedAddress('TwoKeyEventSource'),
                        conversionHandlerAddress,
                        data.moderator || from,
                        data.assetContractERC20,
                        [
                            data.expiryConversion,
                            data.moderatorFeePercentageWei,
                            data.maxReferralRewardPercentWei,
                            data.referrerQuota || 5
                        ],
                        this.base.twoKeyUpgradableExchange.address,
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
                const twoKeyAcquisitionLogicHandler = await promisify(campaignInstance.twoKeyAcquisitionLogicHandler,[{from}]);
                const twoKeyAcquisitionLogicHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyAcquisitionLogicHandler.abi).at(twoKeyAcquisitionLogicHandler);
                const txHash: string = await promisify(twoKeyAcquisitionLogicHandlerInstance.updateOrSetIpfsHashPublicMeta, [hash, {
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
                const twoKeyAcquisitionLogicHandler = await promisify(campaignInstance.twoKeyAcquisitionLogicHandler,[{from}]);
                const twoKeyAcquisitionLogicHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyAcquisitionLogicHandler.abi).at(twoKeyAcquisitionLogicHandler);
                const ipfsHash = await promisify(twoKeyAcquisitionLogicHandlerInstance.publicMetaHash, []);
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
                // await this.visit(campaign, hash);
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
                    const plasmaAddress = this.base.plasmaAddress;
                    const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                    const contractorAddress = await promisify(campaignInstance.contractor, []);
                    // const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    const contractConstants = (await promisify(campaignInstance.getConstantInfo, []));
                    // const decimals = contractConstants[3].toNumber();
                    // this.base._log('Decimals', decimals);
                    let f_address = await promisify(this.base.twoKeyPlasmaEvents.visited_from, [
                        campaignInstance.address,
                        contractorAddress,
                        plasmaAddress,
                    ]);

                    let f_secret = await promisify(this.base.twoKeyPlasmaEvents.notes, [
                        campaignInstance.address,
                        plasmaAddress,
                    ]);
                    f_secret = await Sign.decrypt(this.base.plasmaWeb3, plasmaAddress, f_secret, { plasma: true });
                    f_secret = Sign.remove0x(f_secret);

                    let p_message = await promisify(this.base.twoKeyPlasmaEvents.visited_sig, [
                        campaignInstance.address,
                        contractorAddress,
                        plasmaAddress,
                    ]);


                    this.base._log('getEstimatedMaximumReferralReward', f_address, contractorAddress);
                    // const maxReferralRewardPercent = new BigNumber(contractConstants[1]).div(10 ** decimals).toNumber();
                    const maxReferralRewardPercent = contractConstants[1].toNumber();


                    this.base._log('maxReferralRewardPercent', maxReferralRewardPercent);
                    if (f_address === contractorAddress) {
                        resolve(maxReferralRewardPercent);
                        return;
                    }
                    const firstAddressInChain = p_message ? `0x${p_message.substring(4, 44)}` : f_address;
                    this.base._log('RefCHAIN', contractorAddress, f_address, firstAddressInChain);
                    let cuts: number[];
                    const firstPublicLink = await promisify(this.base.twoKeyPlasmaEvents.publicLinkKeyOf, [
                        campaignInstance.address,
                        contractorAddress,
                        firstAddressInChain,
                    ]);
                    if (firstAddressInChain === contractorAddress) {
                        this.base._log('First public Link', firstPublicLink);
                        cuts = Sign.validate_join(firstPublicLink, f_address, f_secret, p_message, plasmaAddress);
                    } else {
                        cuts = (await promisify(campaignInstance.getReferrerCuts, [firstAddressInChain])).map(cut => cut.toNumber());
                        cuts = cuts.concat(Sign.validate_join(firstPublicLink, f_address, f_secret, p_message, plasmaAddress));
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
    public visit(handle: string, campaignAddress: string, referralLink: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                const plasmaAddress = this.base.plasmaAddress;
                const sig = Sign.free_take(plasmaAddress, f_address, f_secret, p_message);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaignAddress);
                const contractor = await promisify(campaignInstance.contractor, []);
                const txHash: string = await promisify(this.base.twoKeyPlasmaEvents.visited, [
                    campaignInstance.address,
                    contractor,
                    sig,
                    {from: plasmaAddress, gasPrice: 0}
                ]);
                const note = await Sign.encrypt(this.base.plasmaWeb3, plasmaAddress, f_secret, { plasma: true });
                await promisify(this.base.twoKeyPlasmaEvents.setNoteByUser, [campaignInstance.address, note, { from: plasmaAddress}]);
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
    public setPublicLinkKey(campaign: any, from: string,  publicLink: string, {cut, gasPrice = this.base._getGasPrice(), progressCallback}: IPublicLinkOpts = {}): Promise<IPublicLinkKey> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const nonce = await this.helpers._getNonce(from);
                const contractor = await promisify(campaignInstance.contractor, [{from}]);
                const txHash = await promisify(campaignInstance.setPublicLinkKey, [
                    publicLink,
                    { from, nonce ,gasPrice }
                ]);

                let plasmaTxHash;
                try {
                    plasmaTxHash = await promisify(this.base.twoKeyPlasmaEvents.setPublicLinkKey, [
                        campaignInstance.address,
                        contractor,
                        publicLink,
                        {from: this.base.plasmaAddress}
                    ]);
                    if (progressCallback) {
                        progressCallback('Plasma.setPublicLinkKey', false, plasmaTxHash);
                    }
                } catch (e) {
                    this.base._log('Plasma setPublicLinkKey error', e);
                }

                const promises = [];
                promises.push(this.utils.getTransactionReceiptMined(txHash));
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
                if (cut != null) {
                    await promisify(campaignInstance.setCut, [cut, {from}]);
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
        return new Promise<string>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const publicLink = await promisify(campaignInstance.publicLinkKeyOf, [from]);
                resolve(publicLink);
            } catch (e) {
                reject(e)
            }
        })
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
                const safeCut = Sign.fixCut(cut);
                const i = 1;
                const plasmaAddress = this.base.plasmaAddress;
                const msg = `0xdeadbeef${campaignAddress.slice(2)}${plasmaAddress.slice(2)}${i.toString(16)}`;
                const signedMessage = await Sign.sign_message(this.base.plasmaWeb3, msg, plasmaAddress, { plasma: true });
                const private_key = this.base.web3.sha3(signedMessage).slice(2, 2 + 32 * 2);
                const public_address = Sign.privateToPublic(Buffer.from(private_key, 'hex'));
                this.base._log('Signature', signedMessage);
                this.base._log(campaignAddress, from, plasmaAddress, safeCut);
                let new_message;
                let contractor;
                let dao;
                if (referralLink) {
                    const {f_address, f_secret, p_message, contractor: campaignContractor, dao: daoAddress} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    contractor = campaignContractor;
                    dao = daoAddress;
                    new_message = Sign.free_join(plasmaAddress, public_address, f_address, f_secret, p_message, safeCut, cutSign);
                } else {
                    const {contractor: campaignContractor} = await this.setPublicLinkKey(campaign, from, `0x${public_address}`, {
                        cut: safeCut,
                        gasPrice,
                        progressCallback,
                    });
                    dao = voting ? daoContract : undefined;
                    contractor = campaignContractor;
                }
                const linkObject: IOffchainData = {
                    campaign: campaignAddress,
                    contractor,
                    f_address: this.base.plasmaAddress,
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
                const campaignLogicHandler = await promisify(campaignInstance.twoKeyLogicHandler,[]);
                const campaignLogicHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyAcquisitionLogicHandler.abi).at(campaignLogicHandler);
                const constants = await promisify(campaignLogicHandlerInstance.getConstantInfo, []);
                let [baseTokens, bonusTokens] = await promisify(campaignLogicHandlerInstance.getEstimatedTokenAmount, [value]);
                baseTokens = this.utils.fromWei(baseTokens, constants[4]);
                baseTokens = BigNumber.isBigNumber(baseTokens) ? baseTokens.toNumber() : parseFloat(baseTokens);
                bonusTokens = this.utils.fromWei(bonusTokens, constants[4]);
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
     * Function to register plasma to ethereum
     * @param {string} from
     * @returns {Promise<string>}
     */
    public registerPlasmaToEthereum(from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            const sig = await Sign.sign_plasma2eteherum(this.base.plasmaAddress, from, this.base.web3);
            this.base._log('Signature', sig);
            try {
                const stored_ethereum_address = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [this.base.plasmaAddress]);
                if (stored_ethereum_address !== from) {
                    let txHash: string = await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum, [sig, {
                        from: this.base.plasmaAddress,
                        gasPrice: 0
                    }]);
                }

            } catch (plasmaErr) {
                this.base._log('Plasma Error:', plasmaErr);
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
    public joinAndConvert(campaign: any, value: string | number | BigNumber, publicLink: string, from: string, {gasPrice = this.base._getGasPrice(), isConverterAnonymous}: IConvertOpts = {}): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(publicLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const prevChain = await promisify(campaignInstance.received_from, [from]);
                const nonce = await this.helpers._getNonce(from);
                let txHash;
                if (!parseInt(prevChain, 16)) {
                    this.base._log('No ARCS call Free Join Take');
                    // const newPublicLink = await this.join(campaignInstance, from, { referralLink: publicLink, cut })
                    const { public_address } = generatePublicMeta();
                    const sig = await Sign.sign_plasma2eteherum(this.base.plasmaAddress, from, this.base.web3);
                    this.base._log('Signature', sig);
                    this.base._log(campaignInstance.address, from, this.base.plasmaAddress);
                    try {
                        const stored_ethereum_address = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [this.base.plasmaAddress]);
                        if (stored_ethereum_address !== from) {
                            txHash = await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum, [sig, {
                                from: this.base.plasmaAddress,
                                gasPrice: 0
                            }]);
                            // await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.plasmaWeb3, timeout: 300000});
                        }

                    } catch (plasmaErr) {
                        this.base._log('Plasma Error:', plasmaErr);
                    }
                    // const signature = Sign.free_join_take(from, public_address, f_address, f_secret, p_message);
                    const signature = Sign.free_take(from, f_address, f_secret, p_message);
                    txHash = await promisify(campaignInstance.joinAndConvert, [signature,false, {
                        from,
                        gasPrice,
                        value,
                        nonce,
                    }]);
                    const receipt = await this.utils.getTransactionReceiptMined(txHash);
                    console.log(receipt);
                    resolve(txHash);
                } else {
                    this.base._log('Previous referrer', prevChain, value);
                    const txHash: string = await promisify(campaignInstance.convert, [false,{
                        from,
                        gasPrice,
                        value,
                        nonce,
                    }]);
                    const receipt = await this.utils.getTransactionReceiptMined(txHash);
                    console.log(receipt);
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
     * @param campaign
     * @param {string | number | BigNumber} value
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public convert(campaign: any, value: string | number | BigNumber, from: string, {gasPrice = this.base._getGasPrice(), isConverterAnonymous}: IConvertOpts = {}) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const sig = await Sign.sign_plasma2eteherum(this.base.plasmaAddress, from, this.base.web3);
                this.base._log('Signature', sig);
                this.base._log(campaignInstance.address, from, this.base.plasmaAddress);
                try {
                    const stored_ethereum_address = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [this.base.plasmaAddress]);
                    if (stored_ethereum_address !== from) {
                        await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum, [sig, {
                            from: this.base.plasmaAddress,
                            gasPrice: 0
                        }]);
                        // await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.plasmaWeb3, timeout: 300000});
                    }
                } catch (plasmaErr) {
                    this.base._log('Plasma Error:', plasmaErr);
                }
                const nonce = await this.helpers._getNonce(from);
                const txHash: string = await promisify(campaignInstance.convert, [false,{
                    from,
                    gasPrice,
                    value,
                    nonce,
                }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
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
     * Function to get all conversion ids for the converter, can be called by converter itself, moderator or contractor
     * @param campaign
     * @param {string} converterAddress
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getConverterConversionIds(campaign: any, converterAddress: string, from: string) : Promise<number[]> {
        return new Promise<number[]>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.conversionHandler,[{from}]);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                const conversionIds = await promisify(conversionHandlerInstance.getConverterConversionIds,[converterAddress,{from}]);
                resolve(conversionIds);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Function to get number of conversions, can be only called by contractor/moderator
     * @param campaign
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getNumberOfConversions(campaign:any, from:string) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.conversionHandler,[{from}]);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                const numberOfConversions = await promisify(conversionHandlerInstance.getNumberOfConversions,[{from}]);
                resolve(numberOfConversions);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Function which gets conversion object, if converter is anonymous will return empty address for him
     * @param campaign
     * @param {number} conversionId
     * @param {string} from
     * @returns {Promise<any>}
     */
    public getConversion(campaign: any, conversionId: number, from: string) : Promise<IConversionObject> {
        return new Promise<IConversionObject>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.conversionHandler,[{from}]);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                let [contractor, contractorProceedsETHWei, converter, state, conversionAmount, maxReferralRewardEthWei, baseTokenUnits,
                bonusTokenUnits, conversionCreatedAt, conversionExpiresAt] = await promisify(conversionHandlerInstance.getConversion,[conversionId,{from}]);
                let obj : IConversionObject = {
                    'contractor' : contractor,
                    'contractorProceedsETHWei' : contractorProceedsETHWei,
                    'converter' : converter,
                    'state' : state,
                    'conversionAmount' : conversionAmount,
                    'maxReferralRewardEthWei' : maxReferralRewardEthWei,
                    'baseTokenUnits' : baseTokenUnits,
                    'bonusTokenUnits' : bonusTokenUnits,
                    'conversionCreatedAt' : conversionCreatedAt,
                    'conversionExpiresAt' : conversionExpiresAt
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Function to get conversion handler address from the Acquisition campaign
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

    /**
     * Can only be called by contractor or moderator
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
     * @param {string} converter
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public executeConversion(campaign: any, conversion_id: number, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const nonce = await this.helpers._getNonce(from);
                const txHash: string = await promisify(conversionHandlerInstance.executeConversion, [conversion_id, {
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
     * Function where converter can cancel by himself one of his conversions which is still pending approval
     * @param campaign
     * @param {number} conversion_id
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public converterCancelConversion(campaign: any, conversion_id: number, from: string, gasPrice: number = this.base._getGasPrice()) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const nonce = await this.helpers._getNonce(from);
                const txHash: string = await promisify(conversionHandlerInstance.converterCancelConversion,[conversion_id, {
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
                const conversionHandler = await promisify(campaignInstance.conversionHandler,[{from}]);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                let [moderatorBalance, moderatorTotalEarnings] = await promisify(conversionHandlerInstance.getModeratorBalanceAndTotalEarnings, [{from}]);
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
    public moderatorAndReferrerWithdraw(campaign: any, from: string, gasPrice: number = this.base._getGasPrice()) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                /**
                 * TODO: If moderator is doing withdraw it will go through conversion handler contract
                 * @type {number}
                 */
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
                const twoKeyAcquisitionLogicHandler = await promisify(campaignInstance.twoKeyAcquisitionLogicHandler,[{from}]);
                const twoKeyAcquisitionLogicHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyAcquisitionLogicHandler.abi).at(twoKeyAcquisitionLogicHandler);
                const currency: string = await promisify(twoKeyAcquisitionLogicHandlerInstance.currency,[{from}]);
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
     * @returns {Promise<IReferrerSummary>}
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

    /**
     * This function will get available balance including 'reserved' tokens
     * @param campaign
     * @param {string} from
     * @returns {Promise<number>}
     */
    public getCurrentAvailableAmountOfTokens(campaign:any, from:string) : Promise<number> {
        return new Promise(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                let availableBalance = await promisify(campaignInstance.getAvailableAndNonReservedTokensAmount,[{from}]);
                resolve(availableBalance);
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
    public setPrivateMetaHash(campaign: any, privateMetaHash: string, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const twoKeyAcquisitionLogicHandler = await promisify(campaignInstance.twoKeyAcquisitionLogicHandler,[{from}]);
                const twoKeyAcquisitionLogicHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyAcquisitionLogicHandler.abi).at(twoKeyAcquisitionLogicHandler);
                let txHash: string = await promisify(twoKeyAcquisitionLogicHandlerInstance.setPrivateMetaHash,[privateMetaHash,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
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
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const twoKeyAcquisitionLogicHandler = await promisify(campaignInstance.twoKeyAcquisitionLogicHandler,[{from}]);
                const twoKeyAcquisitionLogicHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyAcquisitionLogicHandler.abi).at(twoKeyAcquisitionLogicHandler);
                let txHash: string = await promisify(twoKeyAcquisitionLogicHandlerInstance.getPrivateMetaHash,[{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Gets stats from conversion handler contract
     * @param campaign
     * @param {string} from
     * @returns {Promise<IConversionStats>}
     */
    public getNumberOfConvertersPerType(campaign: any, from: string) : Promise<IConversionStats> {
        return new Promise<IConversionStats>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.conversionHandler,[{from}]);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                const {pending,approved,rejected,totalRaised} = await promisify(conversionHandlerInstance.getNumberOfConvertersPerType,[{from}]);
                resolve(
                    {
                        pendingConverters: pending,
                        approvedConverters: approved,
                        rejectedConverters: rejected,
                        totalETHRaised: totalRaised
                    }
                )
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * This is method to get constant values from acquisition logic handler
     * @param campaign
     * @returns {Promise<IConstantsLogicHandler>}
     */
    public getConstantsFromLogicHandler(campaign:any) : Promise<IConstantsLogicHandler> {
        return new Promise<IConstantsLogicHandler>(async(resolve,reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const twoKeyAcquisitionLogicHandler = await promisify(campaignInstance.twoKeyAcquisitionLogicHandler,[]);
                const twoKeyAcquisitionLogicHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyAcquisitionLogicHandler.abi).at(twoKeyAcquisitionLogicHandler);
                let [
                        campaignStartTime,
                        campaignEndTime,
                        minContributionETHorFiatCurrency,
                        maxContributionETHorFiatCurrency,
                        unit_decimals,
                        pricePerUnitInETHWeiOrUSD,
                        maxConverterBonusPercent
                ] = await promisify(twoKeyAcquisitionLogicHandlerInstance.getConstantInfo,[]);

                let obj : IConstantsLogicHandler = {
                    campaignStartTime: campaignStartTime.toNumber(),
                    campaignEndTime: campaignEndTime.toNumber(),
                    minContributionETHorFiatCurrency: parseFloat(this.utils.fromWei(minContributionETHorFiatCurrency, 'ether').toString()),
                    maxContributionETHorFiatCurrency: parseFloat(this.utils.fromWei(maxContributionETHorFiatCurrency, 'ether').toString()),
                    unit_decimals: unit_decimals.toNumber(),
                    pricePerUnitInETHWeiOrUSD: parseFloat(this.utils.fromWei(pricePerUnitInETHWeiOrUSD, 'ether').toString()),
                    maxConverterBonusPercent: parseFloat(this.utils.fromWei(maxConverterBonusPercent, 'ether').toString()),
                };

                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }
}