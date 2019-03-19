import {ICreateOpts, IERC20, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils} from '../interfaces';
import {
    IAcquisitionCampaign,
    IAcquisitionCampaignMeta, IAddressStats, IConstantsLogicHandler, IConversionObject, IConversionStats,
    IConvertOpts,
    IJoinLinkOpts,
    IPublicLinkKey,
    IPublicLinkOpts,
    IReferrerSummary,
    ITokenAmount,
    ITwoKeyAcquisitionCampaign,
    ILockupInformation,
    IPublicMeta,
    IOffchainData, IContractorBalance, IGetStatsOpts,
} from './interfaces';

import { BigNumber } from 'bignumber.js/bignumber';
import acquisitionContracts from '../contracts/acquisition';
import { promisify } from '../utils/promisify';
import { ISign } from '../sign/interface';

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
            referrerRewardPercent *= (100. - cut) / 100.;
        } else {  // cut = 0 or 255 inidicate equal divistion down stream
            let n = cuts.length - i + 1; // how many influencers including us will split the bounty
            referrerRewardPercent *= (n - 1.) / n;
        }
    }
    return referrerRewardPercent;
}

export default class AcquisitionCampaign implements ITwoKeyAcquisitionCampaign {
    public readonly nonSingletonsHash: string;
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;
    private readonly erc20: IERC20;
    private readonly sign: ISign;
    private AcquisitionCampaign: any;
    private AcquisitionConversionHandler: any;
    private AcquisitionLogicHandler: any;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils, erc20: IERC20, sign: ISign) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
        this.erc20 = erc20;
        this.sign = sign;
        this.nonSingletonsHash = acquisitionContracts.NonSingletonsHash;
        // console.log('ACQUISITION', this.nonSingletonsHash, this.nonSingletonsHash.length);
    }

    /**
     *
     * @returns {{private_key: string; public_address: string}}
     */
    generatePublicMeta(): IPublicMeta {
        let pk = this.sign.generatePrivateKey();
        let public_address = this.sign.privateToPublic(Buffer.from(pk,'hex'));
        const private_key = pk;
        return {private_key, public_address};
    }

    /**
     *
     * @returns {string}
     */
    public getNonSingletonsHash() : string {
        return this.nonSingletonsHash;
    }

    /**
     *
     * @param lockupContract
     * @returns {Promise<any>}
     * @private
     */
    async _getLockupContractInstance(lockupContract: any) : Promise<any> {
        return lockupContract.address
            ? lockupContract
            : await this.helpers._createAndValidate(acquisitionContracts.TwoKeyLockupContract.abi, lockupContract);
    }

    async _getCampaignInstance(campaign: any, skipCache?: boolean): Promise<any> {
        const address = campaign.address || campaign;
        this.base._log('Requesting TwoKeyAcquisitionCampaignERC20 at', address);
        if (campaign.address) {
            return campaign;
        } else {
            return (await this.helpers._createAndValidate(acquisitionContracts.TwoKeyAcquisitionCampaignERC20.abi, campaign));
        }
        /*
        if (skipCache) {
            const campaignInstance = await this.helpers._createAndValidate(acquisitionContracts.TwoKeyAcquisitionCampaignERC20.abi, campaign);
            return campaignInstance;
        }
        if (this.AcquisitionCampaign && this.AcquisitionCampaign.address === address
            && this.AcquisitionConversionHandler && this.AcquisitionConversionHandler.acquisitionAddress === address
            && this.AcquisitionLogicHandler && this.AcquisitionLogicHandler.acquisitionAddress === address) {
            this.base._log('Return from cache TwoKeyAcquisitionCampaignERC20 at', this.AcquisitionCampaign.address);
            return this.AcquisitionCampaign;
        }
        this.base._log('Instantiate new TwoKeyAcquisitionCampaignERC20 at', address, this.AcquisitionCampaign);
        if (campaign.address) {
            this.AcquisitionCampaign = campaign;
        } else {
            this.AcquisitionCampaign = await this.helpers._createAndValidate(acquisitionContracts.TwoKeyAcquisitionCampaignERC20.abi, campaign);
        }
        this.base._log('Requesting Acquisitions helpers contract addresses');
        const [conversionHandler, twoKeyAcquisitionLogicHandler] = await Promise.all([
            promisify(this.AcquisitionCampaign.conversionHandler, []),
            promisify(this.AcquisitionCampaign.twoKeyAcquisitionLogicHandler,[])
        ]);
        this.base._log('Requesting ConversionHandler and LogicHandler', conversionHandler, twoKeyAcquisitionLogicHandler);
        const [AcquisitionConversionHandler, AcquisitionLogicHandler] = await Promise.all([
            this.helpers._createAndValidate(acquisitionContracts.TwoKeyConversionHandler.abi, conversionHandler),
            this.helpers._createAndValidate(acquisitionContracts.TwoKeyAcquisitionLogicHandler.abi, twoKeyAcquisitionLogicHandler),
        ]);
        // this.base._log('ConversionHandler and LogicHandler', AcquisitionConversionHandler, AcquisitionLogicHandler);
        this.AcquisitionConversionHandler = AcquisitionConversionHandler;
        this.AcquisitionConversionHandler.acquisitionAddress = this.AcquisitionCampaign.address;
        this.AcquisitionLogicHandler = AcquisitionLogicHandler;
        this.AcquisitionLogicHandler.acquisitionAddress = this.AcquisitionCampaign.address;
        return this.AcquisitionCampaign;
        */
    }

    async _getConversionHandlerInstance(campaign: any): Promise<any> {
        const acquisitionInstance = await this._getCampaignInstance(campaign);
        const conversionHandlerAddress = await promisify(acquisitionInstance.conversionHandler, []);
        return this.base.web3.eth.contract(acquisitionContracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
        /*
        const address = campaign.address || campaign;
        if (this.AcquisitionConversionHandler && this.AcquisitionConversionHandler.acquisitionAddress === address) {
            return this.AcquisitionConversionHandler;
        }
        await this._getCampaignInstance(campaign);
        // this.base._log('Return ConversionHandler', this.AcquisitionConversionHandler);
        return this.AcquisitionConversionHandler;
        */
    }

    async _getLogicHandlerInstance(campaign: any): Promise<any> {
        const acquisitionInstance = await this._getCampaignInstance(campaign);
        const logicHandlerAddress = await promisify(acquisitionInstance.twoKeyAcquisitionLogicHandler, []);
        return this.base.web3.eth.contract(acquisitionContracts.TwoKeyAcquisitionLogicHandler.abi).at(logicHandlerAddress);
        /*
        const address = campaign.address || campaign;
        if (this.AcquisitionLogicHandler && this.AcquisitionLogicHandler.acquisitionAddress === address) {
            return this.AcquisitionLogicHandler;
        }
        await this._getCampaignInstance(campaign);
        // this.base._log('Return LogicHandler', this.AcquisitionLogicHandler);
        return this.AcquisitionLogicHandler;
        */
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
                const {public_address} = this.generatePublicMeta();
                const predeployGasConversionHandler = await this.helpers._estimateSubcontractGas(acquisitionContracts.TwoKeyConversionHandler, from,
                    [
                        data.tokenDistributionDate,
                        data.maxDistributionDateShiftInDays,
                        data.bonusTokensVestingMonths,
                        data.bonusTokensVestingStartShiftInDaysFromDistributionDate,
                    ]);

                const predeployGasLogicHandler = await this.helpers._estimateSubcontractGas(acquisitionContracts.TwoKeyAcquisitionLogicHandler, from,
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


                const campaignGas = await this.helpers._estimateSubcontractGas(acquisitionContracts.TwoKeyAcquisitionCampaignERC20, from, [
                    `0x${public_address}`,
                    this.base.twoKeyEventSource.address,
                    // Fake WhiteListInfluence address
                    `0x${public_address}`,
                    // Fake WhiteListConverter address
                    data.moderator || from,
                    data.assetContractERC20,
                    data.expiryConversion,
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
                if (this.nonSingletonsHash !== this.base.nonSingletonsHash) {
                    reject(new Error('To start new campaign please switch to latest version of AcquisitionSubmodule'));
                    return;
                }
                let txHash: string;
                const symbol = await this.erc20.getERC20Symbol(data.assetContractERC20);
                if (!symbol) {
                    reject('Invalid ERC20 address');
                    return;
                }
                console.log('twoKeyBaseReputationRegistry', this.base.twoKeyBaseReputationRegistry.address);
                /**
                 * Creating and deploying conversion handler contract
                 */
                let conversionHandlerAddress = data.conversionHandlerAddress;
                if (!conversionHandlerAddress) {
                    this.base._log([data.tokenDistributionDate, data.maxDistributionDateShiftInDays, data.bonusTokensVestingMonths, data.bonusTokensVestingStartShiftInDaysFromDistributionDate], gasPrice);
                    txHash = await this.helpers._createContract(acquisitionContracts.TwoKeyConversionHandler, from, {
                        gasPrice,
                        params: [
                            data.expiryConversion,
                            data.tokenDistributionDate,
                            data.maxDistributionDateShiftInDays,
                            data.bonusTokensVestingMonths,
                            data.bonusTokensVestingStartShiftInDaysFromDistributionDate,
                        ],
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
                    txHash = await this.helpers._createContract(acquisitionContracts.TwoKeyAcquisitionLogicHandler, from, {
                        gasPrice,
                        params: [
                            data.minContributionETHWei,
                            data.maxContributionETHWei,
                            data.pricePerUnitInETHWei,
                            data.campaignStartTime,
                            data.campaignEndTime,
                            data.maxConverterBonusPercentWei,
                            data.currency,
                            data.assetContractERC20,
                            data.moderator
                        ],
                        progressCallback,
                        link: [
                            {
                                name: 'Call',
                                address: this.base.twoKeyCall.address,
                            },
                        ]
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
                txHash = await this.helpers._createContract(acquisitionContracts.TwoKeyAcquisitionCampaignERC20, from, {
                    gasPrice,
                    params: [
                        this.base.twoKeySingletonesRegistry.address,
                        twoKeyAcquisitionLogicHandlerAddress,
                        conversionHandlerAddress,
                        data.moderator || from,
                        data.assetContractERC20,
                        [data.maxReferralRewardPercentWei, data.referrerQuota || 5],
                        ],
                    progressCallback,
                    link: [
                            {
                                name: 'Call',
                                address: this.base.twoKeyCall.address,
                            },
                        ]
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
                const campaignPublicLinkKey = await this.join(campaignAddress, from, {gasPrice, progressCallback, interval, timeout});
                if (progressCallback) {
                    progressCallback('SetPublicLinkKey', true, campaignPublicLinkKey);
                }
                //Here I need also a hash of non singletone at the moment
                txHash = await promisify(this.base.twoKeyCampaignValidator.validateAcquisitionCampaign,[campaignAddress,this.nonSingletonsHash,{from}]);
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
                    conversionHandlerAddress,
                    campaignPublicLinkKey,
                    ephemeralContractsVersion: this.nonSingletonsHash,
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
                const txHash: string = await promisify(this.base.twoKeyAdmin.twoKeyEventSourceAddAuthorizedContracts, [campaignAddress, {from}]);
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
                console.log('updateOrSetIpfsHashPublicMeta', hash);
                const twoKeyAcquisitionLogicHandlerInstance = await this._getLogicHandlerInstance(campaign);
                console.log('twoKeyAcquisitionLogicHandlerInstance', twoKeyAcquisitionLogicHandlerInstance.address);
                const txHash: string = await promisify(twoKeyAcquisitionLogicHandlerInstance.updateOrSetIpfsHashPublicMeta, [hash, {
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
                const twoKeyAcquisitionLogicHandlerInstance = await this._getLogicHandlerInstance(campaign);
                const ipfsHash = await promisify(twoKeyAcquisitionLogicHandlerInstance.publicMetaHash, []);
                const meta = JSON.parse((await promisify(this.base.ipfsR.cat, [ipfsHash])).toString());
                resolve({meta});
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
                const logicHandlerInstance = await this._getLogicHandlerInstance(campaign);
                const balance = await promisify(logicHandlerInstance.getInventoryBalance, [{from}]);
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
        return new Promise<number>(async(resolve,reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign);
                let availableBalance = await promisify(campaignInstance.getAvailableAndNonReservedTokensAmount,[{from}]);
                resolve(availableBalance);
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
    public async getReferrerCut(campaign: any, from: string): Promise<number> {
        try {
            const campaignInstance = await this._getCampaignInstance(campaign);
            const cut = (await promisify(campaignInstance.getReferrerCut, [from, {from}])).toNumber() + 1;
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
                    const campaignInstance = await this._getCampaignInstance(campaign);
                    const contractorAddress = await promisify(campaignInstance.contractor, []);
                    const offchainData = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    const contractConstants = (await promisify(campaignInstance.getConstantInfo, []));
                    const { f_address, f_secret, p_message } = offchainData;
                    const sig = this.sign.free_take(plasmaAddress, f_address, f_secret, p_message);

                    this.base._log('getEstimatedMaximumReferralReward', f_address, contractorAddress);
                    const maxReferralRewardPercent = contractConstants[1].toNumber();


                    this.base._log('maxReferralRewardPercent', maxReferralRewardPercent);
                    if (f_address === contractorAddress) {
                        resolve(maxReferralRewardPercent);
                        return;
                    }
                    const firstAddressInChain = p_message ? `0x${p_message.substring(2, 42)}` : f_address;
                    this.base._log('RefCHAIN', contractorAddress, f_address, firstAddressInChain);
                    let cuts: number[];
                    const firstPublicLink = await promisify(campaignInstance.publicLinkKeyOf, [firstAddressInChain]);
                    this.base._log('Plasma publicLink', firstPublicLink);
                    if (firstAddressInChain === contractorAddress) {
                        this.base._log('First public Link', firstPublicLink);
                        cuts = this.sign.validate_join(firstPublicLink, f_address, f_secret, sig, plasmaAddress);
                    } else {
                        cuts = (await promisify(campaignInstance.getReferrerCuts, [firstAddressInChain])).map(cut => cut.toNumber());
                        this.base._log('CUTS from', firstAddressInChain, cuts);
                        cuts = cuts.concat(this.sign.validate_join(firstPublicLink, f_address, f_secret, sig, plasmaAddress));
                    }
                    // TODO: Andrii removing CONTRACTOR 0 cut from cuts;
                    cuts.shift();
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
                const plasmaAddress = this.base.plasmaAddress;
                const sig = this.sign.free_take(plasmaAddress, f_address, f_secret, p_message);
                const campaignInstance = await this._getCampaignInstance(campaignAddress);
                const contractor = await promisify(campaignInstance.contractor, []);
                const joinedFrom = await promisify(this.base.twoKeyPlasmaEvents.joined_from, [campaignInstance.address, contractor, plasmaAddress]);
                this.base._log('contractor', contractor, plasmaAddress);
                const txHash: string = await promisify(this.base.twoKeyPlasmaEvents.visited, [
                    campaignInstance.address,
                    contractor,
                    sig,
                    {from: plasmaAddress, gasPrice: 0}
                ]);
                this.base._log('visit txHash', txHash);
                if (!parseInt(joinedFrom, 16)) {
                    await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.plasmaWeb3});
                    const note = await this.sign.encrypt(this.base.plasmaWeb3, plasmaAddress, f_secret, {plasma: true});
                    const noteTxHash = await promisify(this.base.twoKeyPlasmaEvents.setNoteByUser, [campaignInstance.address, note, {from: plasmaAddress}]);
                    this.base._log('note txHash', noteTxHash);
                }
                resolve(txHash);
            } catch (e) {
                console.error(e);
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
                const campaignInstance = await this._getCampaignInstance(campaign);
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
                    campaign_web3_address: campaignAddress,
                    contractor,
                    f_address: plasmaAddress,
                    f_secret: private_key,
                    ephemeralContractsVersion: this.nonSingletonsHash,
                    campaign_type: 'acquisition',
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
                const campaignInstance = await this._getCampaignInstance(campaign);
                let arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [from])).toString());
                const {public_address, private_key} = this.generatePublicMeta();

                if (!arcBalance) {
                    this.base._log('No Arcs', arcBalance, 'Call Free Join Take');
                    const signature = this.sign.free_join_take(from, public_address, f_address, f_secret, p_message, cut + 1);
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
                const campaignInstance = await this._getCampaignInstance(campaign);
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
     * @param {boolean} isPaymentFiat
     * @param {string | number | BigNumber} value
     * @returns {Promise<ITokenAmount>}
     */
    public getEstimatedTokenAmount(campaign: any, isPaymentFiat: boolean, value: string | number | BigNumber): Promise<ITokenAmount> {
        return new Promise<ITokenAmount>(async (resolve, reject) => {
            try {
                const twoKeyAcquisitionLogicHandlerInstance = await this._getLogicHandlerInstance(campaign);
                const constants = await promisify(twoKeyAcquisitionLogicHandlerInstance.getConstantInfo, []);
                let [baseTokens, bonusTokens] = await promisify(twoKeyAcquisitionLogicHandlerInstance.getEstimatedTokenAmount, [value, isPaymentFiat]);
                baseTokens = this.utils.fromWei(baseTokens, constants[4]);
                baseTokens = parseFloat(baseTokens.toString());
                bonusTokens = this.utils.fromWei(bonusTokens, constants[4]);
                bonusTokens = parseFloat(bonusTokens.toString());
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
                    this.base._log('No ARCS call Free Join');
                    const plasmaAddress = this.base.plasmaAddress;
                    const signature = this.sign.free_take(plasmaAddress, f_address, f_secret, p_message);

                    const cuts = this.sign.validate_join(null, null, null, signature, plasmaAddress);
                    console.log('CUTS', cuts);
                    console.log('Sig we want to buy with is: ' + signature);
                    console.log(`Plasma of ${from} is`, await promisify(this.base.twoKeyReg.getEthereumToPlasma, [from]));
                    txHash = await promisify(campaignInstance.joinAndConvert, [signature,false, {
                        from,
                        gasPrice,
                        value,
                        nonce,
                    }]);
                    this.base._log('joinAndConvert txHash', txHash);

                    try {
                        const contractor = await promisify(campaignInstance.contractor, []);

                        console.log('twoKeyPlasmaEvents.joinCampaign convert', campaignInstance.address, contractor, signature, plasmaAddress);
                        await this.helpers._awaitPlasmaMethod(promisify(this.base.twoKeyPlasmaEvents.joinCampaign, [campaignInstance.address, contractor, signature, { from: plasmaAddress, gasPrice: 0 }]));
                    } catch (e) {
                        console.log('Plasma joinCampaign error', e);
                    }
                    resolve(txHash);
                } else {
                    this.base._log('Previous referrer', prevChain, value);
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
     * @param campaign
     * @param {string | number | BigNumber} value
     * @param {string} from
     * @param {number} gasPrice
     * @param {boolean} isConverterAnonymous
     * @returns {Promise<string>}
     */
    public convert(campaign: any, value: string | number | BigNumber, from: string, {gasPrice = this.base._getGasPrice(), isConverterAnonymous}: IConvertOpts = {}) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign);
                this.base._log(campaignInstance.address, from, this.base.plasmaAddress);
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
                const campaignInstance = await this._getCampaignInstance(campaign);
                const arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [from])).toString());
                const prevChain = await promisify(campaignInstance.getReceivedFrom, [recipient]);
                if (parseInt(prevChain, 16)) {
                    reject(new Error('User already in chain'));
                }
                const nonce = await this.helpers._getNonce(from);
                if (!arcBalance) {
                    const {public_address} = this.generatePublicMeta();
                    this.base._log('joinAndShareARC call Free Join Take');
                    const signature = this.sign.free_take(this.base.plasmaAddress, f_address, f_secret, p_message);
                    this.base._log(signature, recipient);
                    //TODO: Wrong link
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
                const logicHandlerInstance = await this._getLogicHandlerInstance(campaign);
                console.log(from);
                resolve(await promisify(logicHandlerInstance.getAddressJoinedStatus, [from,{from}]));
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
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
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
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
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
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
                let contractor, contractorProceedsETHWei, converter, state, conversionAmount, maxReferralRewardEthWei, maxReferralRewardTwoKey, moderatorFeeETHWei, baseTokenUnits,
                bonusTokenUnits, conversionCreatedAt, conversionExpiresAt, isConversionFiat, lockupContractAddress;
                let hexedValues = await promisify(conversionHandlerInstance.getConversion,[conversionId,{from}]);
                contractor = hexedValues.slice(0, 42);
                contractorProceedsETHWei = parseInt(hexedValues.slice(42, 42+64),16);
                converter = '0x' + hexedValues.slice(42+64,42+64+40);
                state = parseInt(hexedValues.slice(42+64+40,42+64+40+2),16);
                conversionAmount = parseInt(hexedValues.slice(42+64+40+2,42+64+40+2+64),16);
                maxReferralRewardEthWei = parseInt(hexedValues.slice(42+64+40+2+64,42+64+40+2+64+64),16);
                maxReferralRewardTwoKey = parseInt(hexedValues.slice(42+64+40+2+64+64,42+64+40+2+64+64+64),16);
                moderatorFeeETHWei = parseInt(hexedValues.slice(42+64+40+2+64+64+64,42+64+40+2+64+64+64+64),16);
                baseTokenUnits = parseInt(hexedValues.slice(42+64+40+2+64+64+64+64,42+64+40+2+64+64+64+64+64),16);
                bonusTokenUnits = parseInt(hexedValues.slice(42+64+40+2+64+64+64+64+64,42+64+40+2+64+64+64+64+64+64),16);
                conversionCreatedAt = parseInt(hexedValues.slice(42+64+40+2+64+64+64+64+64+64,42+64+40+2+64+64+64+64+64+64+64),16);
                conversionExpiresAt = parseInt(hexedValues.slice(42+64+40+2+64+64+64+64+64+64,42+64+40+2+64+64+64+64+64+64+64),16);
                isConversionFiat = parseInt(hexedValues.slice(42+64+40+2+64+64+64+64+64+64+64+64,42+64+40+2+64+64+64+64+64+64+64+2+64),16) == 1;
                lockupContractAddress = '0x' + hexedValues.slice(42+64+40+2+64+64+64+64+64+64+64+2+64);


                if(state == 0) {
                    state = 'PENDING_APPROVAL';
                } else if(state == 1) {
                    state = 'APPROVED';
                } else if(state == 2) {
                    state = 'EXECUTED';
                } else if(state == 3) {
                    state = 'REJECTED';
                } else if(state == 4) {
                    state = 'CANCELLED_BY_CONVERTER';
                }


                let obj : IConversionObject = {
                    'contractor' : contractor,
                    'contractorProceedsETHWei' : parseFloat(this.utils.fromWei(contractorProceedsETHWei, 'ether').toString()),
                    'converter' : converter,
                    'state' : state.toString(),
                    'conversionAmount' : parseFloat(this.utils.fromWei(conversionAmount, 'ether').toString()),
                    'maxReferralRewardEthWei' : parseFloat(this.utils.fromWei(maxReferralRewardEthWei, 'ether').toString()),
                    'maxReferralReward2key' : parseFloat(this.utils.fromWei(maxReferralRewardTwoKey, 'ether').toString()),
                    'moderatorFeeETHWei' : parseFloat(this.utils.fromWei(moderatorFeeETHWei, 'ether').toString()),
                    'baseTokenUnits' : parseFloat(this.utils.fromWei(baseTokenUnits, 'ether').toString()),
                    'bonusTokenUnits' : parseFloat(this.utils.fromWei(bonusTokenUnits, 'ether').toString()),
                    'conversionCreatedAt' : conversionCreatedAt,
                    'conversionExpiresAt' : conversionExpiresAt,
                    'isConversionFiat' : isConversionFiat,
                    'lockupContractAddress' : lockupContractAddress
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {boolean} skipCache
     * @returns {Promise<string>}
     */
    public getTwoKeyConversionHandlerAddress(campaign: any, skipCache?: boolean): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign, skipCache);
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
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
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
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
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
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
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
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
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
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
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
     * @param {number} conversion_id
     * @param {string} from
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public executeConversion(campaign: any, conversion_id: number, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(acquisitionContracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const nonce = await this.helpers._getNonce(from);
                console.log('Nonce is' + nonce);
                const txHash: string = await promisify(conversionHandlerInstance.executeConversion, [conversion_id, {
                    from,
                    gasPrice,
                    nonce
                }]);
                console.log(txHash);
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
                const conversionHandlerInstance = this.base.web3.eth.contract(acquisitionContracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
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
     * @param {boolean} skipCache
     * @returns {Promise<string[]>}
     */
    public getLockupContractsForConverter(campaign: any, converter: string, from: string, skipCache?: boolean): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign, skipCache);
                const conversionHandlerInstance = this.base.web3.eth.contract(acquisitionContracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
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
                const campaignInstance = await this._getCampaignInstance(campaign);
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
                const campaignInstance = await this._getCampaignInstance(campaign);
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
                const campaignInstance = await this._getCampaignInstance(campaign);
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
                const campaignInstance = await this._getCampaignInstance(campaign);
                let value: number = await promisify(campaignInstance.getAmountAddressSent, [from]);
                value = parseFloat(this.utils.fromWei(value, 'ether').toString());
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
                const campaignInstance = await this._getCampaignInstance(campaign);
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
    public getContractorBalance(campaign: any, from: string): Promise<IContractorBalance> {
        return new Promise<IContractorBalance>(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign);
                let [available, total] = await promisify(campaignInstance.getContractorBalanceAndTotalProceeds, [{from}]);
                available = parseFloat(this.utils.fromWei(available, 'ether').toString());
                total = parseFloat(this.utils.fromWei(total, 'ether').toString());
                resolve({ available, total });
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
                const campaignInstance = await this._getCampaignInstance(campaign);
                let [moderatorBalance, moderatorTotalEarnings] = await promisify(campaignInstance.getModeratorBalanceAndTotalEarnings, [{from}]);
                moderatorBalance = parseFloat(this.utils.fromWei(moderatorBalance, 'ether').toString());
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
                let balance = await this.erc20.getERC20Balance(this.base.twoKeyEconomy.address, this.base.twoKeyUpgradableExchange.address);
                balance = parseFloat(this.utils.fromWei(balance, 'ether').toString());
                console.log("Balance of 2keys on upgradable exchange is: " + balance);
                const campaignInstance = await this._getCampaignInstance(campaign);
                const txHash: string = await promisify(campaignInstance.withdrawModeratorOrReferrer,[from,
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
                const campaignInstance = await this._getCampaignInstance(campaign);
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
                const twoKeyAcquisitionLogicHandlerInstance = await this._getLogicHandlerInstance(campaign);
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
                const campaignInstance = await this._getCampaignInstance(campaign);
                let [moderatorBalance,moderatorBalanceTotal] = await promisify(campaignInstance.getModeratorBalanceAndTotalEarnings,[{from}]);
                moderatorBalanceTotal = parseFloat(this.utils.fromWei(moderatorBalanceTotal, 'ether').toString());
                resolve(moderatorBalanceTotal);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     *
     * @param campaign
     * @param {string} signature
     * @param {boolean} skipCache
     * @returns {Promise<IReferrerSummary>}
     */
    public getReferrerBalanceAndTotalEarningsAndNumberOfConversions(campaign:any, signature: string, skipCache?: boolean) : Promise<IReferrerSummary> {
        return new Promise<any>(async(resolve,reject) => {
           try {
               const campaignInstance = await this._getCampaignInstance(campaign, skipCache);
               let [referrerBalanceAvailable, referrerTotalEarnings, referrerInCountOfConversions, contributions] =
                   await promisify(campaignInstance.getReferrerBalanceAndTotalEarningsAndNumberOfConversions,['0x0',signature, []]);
               const obj = {
                   balanceAvailable: parseFloat(this.utils.fromWei(referrerBalanceAvailable, 'ether').toString()),
                   totalEarnings: parseFloat(this.utils.fromWei(referrerTotalEarnings, 'ether').toString()),
                   numberOfConversionsParticipatedIn : parseFloat(referrerInCountOfConversions.toString()),
                   campaignAddress: campaignInstance.address,
                   rewardsPerConversions: contributions.map(item => parseFloat(this.utils.fromWei(item, 'ether').toString())),
               };
               resolve(obj)
           } catch (e) {
               reject(e);
           }
        });
    }

    /**
     *
     * @param campaign
     * @param {string} signature
     * @param {number[]} conversionIds
     * @param {boolean} skipCache
     * @returns {Promise<number[]>}
     */
    public getReferrerRewardsPerConversion(campaign:any, signature: string, conversionIds: number[], skipCache?: boolean) : Promise<number[]> {
        return new Promise<number[]>(async(resolve,reject) => {
            try {
                const campaignInstance = await this._getCampaignInstance(campaign, skipCache);
                let [,,,contributionsPerReferrer] =
                    await promisify(campaignInstance.getReferrerBalanceAndTotalEarningsAndNumberOfConversions,['0x0',signature, conversionIds]);
                resolve(contributionsPerReferrer);
            } catch (e) {
                reject(e);
            }
        })
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
                const campaignInstance = await this._getCampaignInstance(campaign);
                let availableBalance = await promisify(campaignInstance.getAvailableAndNonReservedTokensAmount,[{from}]);
                resolve(parseFloat(this.utils.fromWei(availableBalance, 'ether').toString()));
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
                const twoKeyAcquisitionLogicHandlerInstance = await this._getLogicHandlerInstance(campaign);
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
                const twoKeyAcquisitionLogicHandlerInstance = await this._getLogicHandlerInstance(campaign);
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
    public getCampaignSummary(campaign: any, from: string) : Promise<IConversionStats> {
        return new Promise<IConversionStats>(async(resolve,reject) => {
            try {
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
                const [pending,approved,rejected,totalRaised,tokensSold,totalBounty] = await promisify(conversionHandlerInstance.getCampaignSummary,[{from}]);
                resolve(
                    {
                        pendingConverters:  pending.toNumber(),
                        approvedConverters:  approved.toNumber(),
                        rejectedConverters:  rejected.toNumber(),
                        totalETHRaised: parseFloat(this.utils.fromWei(totalRaised, 'ether').toString()),
                        tokensSold: parseFloat(this.utils.fromWei(tokensSold,'ether').toString()),
                        totalBounty: parseFloat(this.utils.fromWei(totalBounty, 'ether').toString())
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
                const twoKeyAcquisitionLogicHandlerInstance = await this._getLogicHandlerInstance(campaign);
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

    /**
     *
     * @param campaign
     * @param {string} address
     * @param {boolean} plasma
     * @returns {Promise<IAddressStats>}
     */
    public getAddressStatistic(campaign: any, address: string, signature: string, {from , plasma = false} : IGetStatsOpts = {}) : Promise<IAddressStats>{
        return new Promise<IAddressStats>(async(resolve,reject) => {
            try {
                const twoKeyAcquisitionLogicHandlerInstance = await this._getLogicHandlerInstance(campaign);

                let username, fullname, email;
                let hex= await promisify(twoKeyAcquisitionLogicHandlerInstance.getSuperStatistics,[address, plasma, signature,{from}]);
                /**
                 *
                 * Unpack bytes for statistics
                 */
                username = hex.slice(0,66);
                fullname = hex.slice(66,66+64);
                email = hex.slice(66+64,66+64+64);


                let isJoined = parseInt(hex.slice(66+64+64,66+64+64+2),16) == 1;
                let ethereumof = '0x' + hex.slice(66+64+64+2, 66+64+64+2+40);
                let amountConverterSpent = parseInt(hex.slice(66+64+64+2+40, 66+64+64+2+40+64),16);
                let rewards = parseInt(hex.slice(66+64+64+2+40+64,66+64+64+2+40+64+64),16);
                let unitsConverterBought = parseInt(hex.slice(66+64+64+2+40+64+64,66+64+64+2+40+64+64+64),16);
                let isConverter = parseInt(hex.slice(66+64+64+2+40+64+64+64,66+64+64+2+40+64+64+64+2),16) == 1;
                let isReferrer = parseInt(hex.slice(66+64+64+2+40+64+64+64+2,66+64+64+2+40+64+64+64+2+2),16) == 1;
                let converterState = hex.slice(66+64+64+2+40+64+64+64+2+2);

                converterState = this.base.web3.toUtf8(converterState);
                if(converterState == '') {
                    converterState = 'NOT_CONVERTER';
                }
                let obj : IAddressStats = {
                    amountConverterSpentETH: parseFloat(this.utils.fromWei(amountConverterSpent,'ether').toString()),
                    referrerRewards : parseFloat(this.utils.fromWei(rewards,'ether').toString()),
                    tokensBought: parseFloat(this.utils.fromWei(unitsConverterBought, 'ether').toString()),
                    isConverter: isConverter,
                    isReferrer: isReferrer,
                    isJoined: isJoined,
                    username: this.base.web3.toUtf8(username),
                    fullName: this.base.web3.toUtf8(fullname),
                    email: this.base.web3.toUtf8(email),
                    ethereumOf: ethereumof,
                    converterState: converterState
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }


    /**
     * Enables converter to do offline conversion
     * @param campaign
     * @param {string} from
     * @param {number} conversionAmountFiat Will be float amount of dollars (example 2345,5$)
     * @param {boolean} isConverterAnonymous
     * @param {number} gasPrice
     * @returns {Promise<string>}
     */
    public convertOffline(campaign: any, _converter: string, from: string, conversionAmountFiat: number, {gasPrice = this.base._getGasPrice(), isConverterAnonymous}: IConvertOpts = {}) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const twoKeyAcquisitionCampaignInstance = await this._getCampaignInstance(campaign);
                console.log('Converter with address : ' + from + 'is trying to perform offline conversion with amount of: ' +conversionAmountFiat);
                conversionAmountFiat = parseFloat(this.utils.toWei(conversionAmountFiat, 'ether').toString());
                console.log('Conversion amount fiat converted to wei is: ' + conversionAmountFiat);
                console.log(conversionAmountFiat, isConverterAnonymous);
                let txHash = await promisify(twoKeyAcquisitionCampaignInstance.convertFiat,[_converter, conversionAmountFiat, false,
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
     * Get lockup contract for the conversion id
     * @param campaign
     * @param {string} from
     * @param {number} conversionId
     * @returns {Promise<string>}
     */
    public getLockupContractAddress(campaign:any, conversionId: number, from:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
                let lockupAddress = await promisify(conversionHandlerInstance.getLockupContractAddress,[conversionId,{from}]);
                resolve(lockupAddress);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Get information from the Lockup contract, it's only available for the Converter
     * @param {string} twoKeyLockup
     * @param {string} from
     * @returns {Promise<ILockupInformation>}
     */
    public getLockupInformations(twoKeyLockup: string, from:string) : Promise<ILockupInformation> {
        return new Promise<ILockupInformation>(async(resolve, reject) => {
            try {
                const twoKeyLockupInstance = await this._getLockupContractInstance(twoKeyLockup);

                let [baseTokens, bonusTokens, vestingMonths, conversionId, unlockingDates, isWithdrawn] =
                    await promisify(twoKeyLockupInstance.getLockupSummary,[{from}]);
                let obj : ILockupInformation = {
                    baseTokens : parseFloat(this.utils.fromWei(baseTokens, 'ether').toString()),
                    bonusTokens : parseFloat(this.utils.fromWei(bonusTokens, 'ether').toString()),
                    vestingMonths : vestingMonths.toNumber(),
                    conversionId : conversionId.toNumber(),
                    unlockingDays : unlockingDates.map(date => parseInt(date.toString(),10)),
                    areWithdrawn : isWithdrawn
                };
                resolve(obj);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Method to withdraw tokens, converter is sending which part he wants to withdraw - only converter can call this
     * @param {string} twoKeyLockup
     * @param {number} part
     * @param {string} from
     * @returns {Promise<string>}
     */
    public withdrawTokens(twoKeyLockup: string, part: number, from:string) : Promise<string> {
        return new Promise(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this._getLockupContractInstance(twoKeyLockup);
                const txHash = await promisify(twoKeyLockupInstance.withdrawTokens, [part,{from}]);
                // await this.utils.getTransactionReceiptMined(txHash);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }




    /**
     * Only contractor can change token distribution date
     * @param {string} twoKeyLockup
     * @param {number} newDate
     * @param {string} from
     * @returns {Promise<string>}
     */
    public changeTokenDistributionDate(twoKeyLockup: string, newDate: number, from: string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const twoKeyLockupInstance = await this._getLockupContractInstance(twoKeyLockup);
                let txHash = await promisify(twoKeyLockupInstance.changeTokenDistributionDate,[newDate,{from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    /**
     * Get number of conversions executed on the contract
     * @param {string} campaign
     * @returns {Promise<number>}
     */
    public getNumberOfExecutedConversions(campaign: string) : Promise<number> {
        return new Promise<number>(async(resolve,reject) => {
            try {
                const conversionHandlerInstance = await this._getConversionHandlerInstance(campaign);
                let numberOfConv = await promisify(conversionHandlerInstance.getNumberOfExecutedConversions,[]);
                resolve(numberOfConv);
            } catch (e) {
                reject(e);
            }
        })
    }

    public testRecover(campaign:string) : Promise<string> {
        return new Promise<string>(async(resolve,reject) => {
            try {
                const logicHandler = await this._getLogicHandlerInstance(campaign);
                let add = await promisify(logicHandler.recover,['0x0']);
                resolve(add);
            } catch (e) {
                reject(e);
            }
        })
    }
}
