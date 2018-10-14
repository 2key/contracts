import {
    IAcquisitionCampaign,
    IAcquisitionCampaignMeta,
    ICreateCampaignProgress, IOffchainData, IPublicLinkKey,
    ITwoKeyBase,
    ITwoKeyHelpers,
    ITWoKeyUtils
} from '../interfaces';
import {BigNumber} from 'bignumber.js';
import contractsMeta, {default as contracts} from '../contracts';
import {promisify} from '../utils';
import Sign from '../utils/sign';

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

function generatePublicMeta(): { private_key: string, public_address: string } {
    let pk = Sign.generatePrivateKey();
    let public_address = Sign.privateToPublic(pk);
    const private_key = pk.toString('hex');
    return {private_key, public_address};
}

export default class AcquisitionCampaign {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITWoKeyUtils;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITWoKeyUtils) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
    }

    /* ACQUISITION CAMPAIGN */

    public estimateCreation(data: IAcquisitionCampaign): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const {public_address} = generatePublicMeta();
                const predeployGas = await this.helpers._estimateSubcontractGas(contractsMeta.TwoKeyConversionHandler,
                    [
                        data.tokenDistributionDate,
                        data.maxDistributionDateShiftInDays,
                        data.bonusTokensVestingMonths,
                        data.bonusTokensVestingStartShiftInDaysFromDistributionDate,
                    ]);
                const campaignGas = await this.helpers._estimateSubcontractGas(contractsMeta.TwoKeyAcquisitionCampaignERC20, [
                    this.helpers._getContractDeployedAddress('TwoKeyEventSource'),
                    this.base.twoKeyEconomy.address,
                    // Fake WhiteListInfluence address
                    `0x${public_address}`,
                    // Fake WhiteListConverter address
                    data.moderator || this.base.address,
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

    // Create Campaign
    public create(data: IAcquisitionCampaign, progressCallback?: ICreateCampaignProgress, gasPrice?: number, interval: number = 500, timeout: number = 60000): Promise<IAcquisitionCampaignMeta> {
        return new Promise(async (resolve, reject) => {
            try {
                let txHash: string;
                let conversionHandlerAddress = data.conversionHandlerAddress;
                if (!conversionHandlerAddress) {
                    this.base._log([data.tokenDistributionDate, data.maxDistributionDateShiftInDays, data.bonusTokensVestingMonths, data.bonusTokensVestingStartShiftInDaysFromDistributionDate], gasPrice);
                    txHash = await this.helpers._createContract(contractsMeta.TwoKeyConversionHandler, gasPrice, [data.tokenDistributionDate, data.maxDistributionDateShiftInDays, data.bonusTokensVestingMonths, data.bonusTokensVestingStartShiftInDaysFromDistributionDate], progressCallback);
                    const predeployReceipt = await this.utils.getTransactionReceiptMined(txHash, this.base.web3, interval, timeout);
                    conversionHandlerAddress = predeployReceipt && predeployReceipt.contractAddress;
                    if (progressCallback) {
                        progressCallback('TwoKeyConversionHandler', true, conversionHandlerAddress);
                    }
                }
                // const whitelistsInstance = this.web3.eth.contract(contractsMeta.TwoKeyWhitelisted.abi).at(whitelistsAddress);

                txHash = await this.helpers._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20, gasPrice, [
                    this.helpers._getContractDeployedAddress('TwoKeyEventSource'),
                    this.base.twoKeyEconomy.address,
                    conversionHandlerAddress,
                    data.moderator || this.base.address,
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
                ], progressCallback);
                const campaignReceipt = await this.utils.getTransactionReceiptMined(txHash, this.base.web3, interval, timeout);
                const campaignAddress = campaignReceipt && campaignReceipt.contractAddress;
                if (progressCallback) {
                    progressCallback('TwoKeyAcquisitionCampaignERC20', true, campaignAddress);
                }
                const campaignPublicLinkKey = await this.join(campaignAddress, -1, undefined, gasPrice);
                if (progressCallback) {
                    progressCallback('SetPublicLinkKey', true, campaignPublicLinkKey);
                }
                resolve({
                    contractor: this.base.address,
                    campaignAddress,
                    conversionHandlerAddress,
                    campaignPublicLinkKey,
                });
            } catch (err) {
                reject(err);
            }
        });
    }

    public addTwoKeyAcquisitionCampaignToBeEligibleToEmitEvents(campaignAddress: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const twoKeyAdminInstance = await this.helpers._getTwoKeyAdminInstance(contractsMeta.TwoKeyAdmin.networks[this.base.networks.mainNetId].address);
                const txHash = await promisify(twoKeyAdminInstance.twoKeyEventSourceAddAuthorizedContracts, [campaignAddress, {from: this.base.address}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    public updateOrSetIpfsHashPublicMeta(campaign: any, hash: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const txHash = await promisify(campaignInstance.updateOrSetIpfsHashPublicMeta, [hash, {
                    from: this.base.address,
                    gasPrice
                }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    public getPublicMeta(campaign: any): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                // const contractor = await promisify(campaignInstance.getContractorAddress, [{from: this.base.address}]);
                // const ipfsHash = await promisify(campaignInstance.publicMetaHash, [{from: this.base.address}]);
                const isAddressJoined = await this.isAddressJoined(campaignInstance);
                const ipfsHash = await promisify(campaignInstance.publicMetaHash, []);
                const meta = JSON.parse((await promisify(this.base.ipfs.cat, [ipfsHash])).toString());
                resolve({meta, isAddressJoined});
            } catch (e) {
                reject(e);
            }
        });
    }

    public getCampaignFromLink(link: string): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const {campaign} = await this.utils.getOffchainDataFromIPFSHash(link);
                await this.visit(campaign, link);
                const campaignMeta = await this.getPublicMeta(campaign);
                resolve(campaignMeta);
            } catch (e) {
                reject(e);
            }
        });
    }

    // Inventory
    public getInventoryBalance(campaign: any): Promise<number | string | BigNumber> {
        return new Promise<number>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const balance = await promisify(campaignInstance.getInventoryBalance, [{from: this.base.address}]);
                resolve(balance);
            } catch (e) {
                reject(e);
            }
        });
    }

    public async checkInventoryBalance(campaign: any): Promise<number | string | BigNumber> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            const hash = await promisify(campaignInstance.getAndUpdateInventoryBalance, [{from: this.base.address}]);
            await this.utils.getTransactionReceiptMined(hash);
            const balance = await promisify(campaignInstance.getInventoryBalance, [{from: this.base.address}]);
            return Promise.resolve(balance);
        } catch (err) {
            Promise.reject(err);
        }
    }

    public async getReferrerCut(campaign: any): Promise<number> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            const cut = (await promisify(campaignInstance.getReferrerCut, [{from: this.base.address}])).toNumber() + 1;
            return Promise.resolve(cut);
        } catch (e) {
            Promise.reject(e);
        }
    }

    // Estimate referral maximum reward
    public getEstimatedMaximumReferralReward(campaign: any, referralLink?: string): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                if (!referralLink) {
                    const cut = await this.getReferrerCut(campaign);
                    resolve(cut);
                } else {
                    const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                    const contractorAddress = await promisify(campaignInstance.getContractorAddress, [{from: this.base.address}]);
                    const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    const contractConstants = (await promisify(campaignInstance.getConstantInfo, [{from: this.base.address}]));
                    const decimals = contractConstants[3].toNumber();
                    this.base._log('Decimals', decimals);
                    const maxReferralRewardPercent = new BigNumber(contractConstants[1]).div(10 ** decimals).toNumber();
                    if (f_address === contractorAddress) {
                        resolve(maxReferralRewardPercent);
                        return;
                    }
                    const firstAddressInChain = p_message ? `0x${p_message.substring(0, 40)}` : f_address;
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

    // Visit link
    public visit(campaignAddress: string, referralLink: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                const sig = Sign.free_take(this.base.plasmaAddress, f_address, f_secret, p_message);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaignAddress);
                const contractor = await promisify(campaignInstance.getContractorAddress, []);
                const txHash = await promisify(this.base.twoKeyPlasmaEvents.visited, [
                    campaignAddress,
                    contractor,
                    sig,
                    {from: this.base.plasmaAddress, gasPrice: 0}
                ]);
                await this.utils.getTransactionReceiptMined(txHash, this.base.plasmaWeb3);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    // Set Public Link
    public setPublicLinkKey(campaign: any, publicLink: string, cut: number, gasPrice: number = this.base._getGasPrice()): Promise<IPublicLinkKey> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const contractor = await promisify(campaignInstance.getContractorAddress, [{from: this.base.address}]);
                const [mainTxHash, plasmaTxHash] = await Promise.all([
                    promisify(campaignInstance.setPublicLinkKey, [publicLink, {
                        from: this.base.address,
                        gasPrice,
                    }]),
                    promisify(this.base.twoKeyPlasmaEvents.setPublicLinkKey, [campaignInstance.address,
                        contractor, this.base.address, publicLink, {from: this.base.plasmaAddress, gasPrice: 0}
                    ]),
                ]);
                await Promise.all([this.utils.getTransactionReceiptMined(mainTxHash), this.utils.getTransactionReceiptMined(plasmaTxHash, this.base.plasmaWeb3)]);
                if (cut > -1) {
                    await promisify(campaignInstance.setCut, [cut, {from: this.base.address}]);
                }
                resolve({publicLink, contractor});
            } catch (err) {
                reject(err);
            }
        });
    }

    // Get Public Link
    public async getPublicLinkKey(campaign: any, address: string = this.base.address): Promise<string> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            const publicLink = await promisify(campaignInstance.publicLinkKey, [address]);
            return Promise.resolve(publicLink);

        } catch (e) {
            Promise.reject(e)
        }
    }

    // Join Offchain
    public join(campaign: any, cut: number, referralLink?: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignAddress = typeof (campaign) === 'string' ? campaign
                    : (await this.helpers._getAcquisitionCampaignInstance(campaign)).address;

                if (this.base.address !== this.base.plasmaAddress) {
                    const {sig, with_prefix} = await Sign.sign_plasma2eteherum(this.base.plasmaAddress, this.base.address, this.base.web3);
                    this.base._log('Signature', sig, with_prefix, this.base.address, this.base.plasmaAddress);
                    const txHash = await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum, [sig, with_prefix, {
                        from: this.base.plasmaAddress,
                        gasPrice: 0
                    }]);
                    await this.utils.getTransactionReceiptMined(txHash, this.base.plasmaWeb3, 500, 300000);
                    const stored_ethereum_address = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [this.base.plasmaAddress]);
                    if (stored_ethereum_address !== this.base.address) {
                        reject(stored_ethereum_address + ' != ' + this.base.address)
                    }
                }

                const {public_address, private_key} = await Sign.generateSignatureKeys(this.base.address, this.base.plasmaAddress, campaignAddress, this.base.web3);

                let new_message;
                let contractor;
                if (referralLink) {
                    const {f_address, f_secret, p_message, contractor: campaignContractor} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    contractor = campaignContractor;
                    this.base._log('New link for', this.base.address, f_address, f_secret, p_message);
                    new_message = Sign.free_join(this.base.address, public_address, f_address, f_secret, p_message, cut + 1);
                } else {
                    const {contractor: campaignContractor} = await this.setPublicLinkKey(campaign, `0x${public_address}`, cut, gasPrice);
                    contractor = campaignContractor;
                }
                const linkObject: IOffchainData = {
                    campaign: campaignAddress,
                    contractor,
                    f_address: this.base.address,
                    f_secret: private_key
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
    public joinAndSetPublicLinkWithCut(campaignAddress: string, referralLink: string, cut?: number, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
            if (!f_address || !f_secret) {
                reject('Broken Link');
            }
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaignAddress);
                let arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [this.base.address])).toString());
                const {public_address, private_key} = generatePublicMeta();

                if (!arcBalance) {
                    this.base._log('No Arcs', arcBalance, 'Call Free Join Take');
                    const signature = Sign.free_join_take(this.base.address, public_address, f_address, f_secret, p_message, cut + 1);
                    const txHash = await promisify(campaignInstance.distributeArcsBasedOnSignature, [signature, {
                        from: this.base.address,
                        gasPrice,
                    }]);
                    this.base._log('setPubLinkWithCut', txHash);
                    await this.utils.getTransactionReceiptMined(txHash);
                    arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [this.base.address])).toString());
                }
                if (arcBalance) {
                    const link = await this.utils.ipfsAdd({f_address: this.base.address, f_secret: private_key});
                    resolve(link);
                } else {
                    reject(new Error('Link is broken!'));
                }
            } catch (err) {
                reject(err);
            }
        });
    }

    /* PARTICIPATE */
    public joinAndConvert(campaign: any, value: number | string | BigNumber, referralLink: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);

                const prevChain = await promisify(campaignInstance.received_from, [this.base.address]);
                if (!parseInt(prevChain, 16)) {
                    this.base._log('No ARCS call Free Join Take');
                    const {public_address} = generatePublicMeta();
                    const signature = Sign.free_join_take(this.base.address, public_address, f_address, f_secret, p_message);
                    const txHash = await promisify(campaignInstance.joinAndConvert, [signature, {
                        from: this.base.address,
                        gasPrice,
                        value
                    }]);
                    await this.utils.getTransactionReceiptMined(txHash);
                    resolve(txHash);
                } else {
                    this.base._log('Previous referrer', prevChain, value);
                    const txHash = await promisify(campaignInstance.convert, [{
                        from: this.base.address,
                        gasPrice,
                        value
                    }]);
                    resolve(txHash);
                }
            } catch (e) {
                this.base._log('joinAndConvert ERROR', e.toString());
                reject(e);
            }
        });
    }

    // Send ARCS to other account
    public joinAndShareARC(campaignAddress: string, referralLink: string, recipient: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaignAddress);
                const arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [this.base.address])).toString());
                const prevChain = await promisify(campaignInstance.received_from, [recipient]);
                if (parseInt(prevChain, 16)) {
                    reject(new Error('User already in chain'));
                }

                if (!arcBalance) {
                    const {public_address} = generatePublicMeta();
                    this.base._log('joinAndShareARC call Free Join Take');
                    const signature = Sign.free_join_take(this.base.address, public_address, f_address, f_secret, p_message);
                    this.base._log(signature, recipient);
                    const txHash = await promisify(campaignInstance.joinAndShareARC, [signature, recipient, {
                        from: this.base.address,
                        gasPrice
                    }]);
                    resolve(txHash);
                } else {
                    const txHash = await promisify(campaignInstance.transfer, [recipient, 1, {
                        from: this.base.address,
                        gasPrice
                    }]);
                    resolve(txHash);
                }
            } catch (e) {
                reject(e);
            }
        });
    }

    /* HELPERS */
    public isAddressJoined(campaign: any): Promise<boolean> {
        return new Promise<boolean>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                resolve(await promisify(campaignInstance.getAddressJoinedStatus, [{from: this.base.address}]));
            } catch (e) {
                reject(e);
            }
        });
    }

    public getConverterConversion(campaign: any, address: string = this.base.address): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.getTwoKeyConversionHandlerAddress, [{from: this.base.address}]);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                const conversion = await promisify(conversionHandlerInstance.conversions, [this.base.address]);
                resolve(conversion);
            } catch (e) {
                reject(e);
            }
        })
    }

    public getTwoKeyConversionHandlerAddress(campaign: any): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.getTwoKeyConversionHandlerAddress, [{from: this.base.address}]);
                resolve(conversionHandler);
            } catch (e) {
                reject(e);
            }
        })
    }

    // public getAssetContractData(campaign: any): Promise<any> {
    //     return new Promise(async (resolve, reject) => {
    //         try {
    //             const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
    //             const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
    //             // const assetContractData = await promisify(conversionHandlerInstance.getContractor, [{ from: this.base.address }]);
    //             // const assetContractData = await promisify(conversionHandlerInstance.getAssetContractData, []);
    //             resolve(assetContractData)
    //         } catch (e) {
    //             reject(e);
    //         }
    //     })
    // }

    public getAllPendingConverters(campaign: any): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const pendingConverters = await promisify(conversionHandlerInstance.getAllPendingConverters, [{from: this.base.address}]);
                resolve(pendingConverters);
            } catch (e) {
                reject(e);
            }
        })
    }

    public approveConverter(campaign: any, converter: string): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash = await promisify(conversionHandlerInstance.approveConverter, [converter, {from: this.base.address}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    public rejectConverter(campaign: any, converter: string): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash = await promisify(conversionHandlerInstance.rejectConverter, [converter, {from: this.base.address}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    public cancelConverter(campaign: any): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash = await promisify(conversionHandlerInstance.cancelConverter, [{from: this.base.address}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    public getApprovedConverters(campaign: any): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const approvedConverters = await promisify(conversionHandlerInstance.getAllApprovedConverters, [{from: this.base.address}]);
                resolve(approvedConverters);
            } catch (e) {
                reject(e);
            }
        })
    }

    public getAllRejectedConverters(campaign: any): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const rejectedConverters = await promisify(conversionHandlerInstance.getAllRejectedConverters, [{from: this.base.address}]);
                resolve(rejectedConverters);
            } catch (e) {
                reject(e);
            }
        })
    }

    public executeConversion(campaign: any, converter: string): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);

                const txHash = await promisify(conversionHandlerInstance.executeConversion, [converter, {from: this.base.address}]);
                this.base._log(txHash);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }


    public getLockupContractsForConverter(campaign: any, converter: string): Promise<string[]> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const lockupContractAddresses = await promisify(conversionHandlerInstance.getLockupContractsForConverter, [converter, {from: this.base.address}]);
                resolve(lockupContractAddresses);
            } catch (e) {
                reject(e);
            }
        });
    }
}
