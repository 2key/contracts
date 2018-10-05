import {IAcquisitionCampaign, ICreateCampaignProgress, ITwoKeyBase, ITwoKeyHelpers, ITWoKeyUtils} from "../interfaces";
import contractsMeta from "../contracts";
import {promisify} from "../utils/index";
import {BigNumber} from "bignumber.js";
import Sign from "../utils/sign";

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
};


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
                console.log('TwoKeyAcquisitionCampaignERC20 gas required', campaignGas);
                const totalGas = predeployGas + campaignGas;
                resolve(totalGas);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Create Campaign
    public create(data: IAcquisitionCampaign, progressCallback?: ICreateCampaignProgress, gasPrice?: number): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                // const gasRequired = await this.estimateCreation(data);
                // await this._checkBalanceBeforeTransaction(gasRequired, gasPrice || this.gasPrice);
                let txHash = await this.helpers._createContract(contractsMeta.TwoKeyConversionHandler, gasPrice, null, progressCallback);
                const predeployReceipt = await this.utils.getTransactionReceiptMined(txHash);
                const whitelistsAddress = predeployReceipt && predeployReceipt.contractAddress;
                if (progressCallback) {
                    progressCallback('TwoKeyConversionHandler', true, whitelistsAddress);
                }
                // const whitelistsInstance = this.web3.eth.contract(contractsMeta.TwoKeyWhitelisted.abi).at(whitelistsAddress);

                txHash = await this.helpers._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20, gasPrice, [
                    this.helpers._getContractDeployedAddress('TwoKeyEventSource'),
                    this.base.twoKeyEconomy.address,
                    whitelistsAddress,
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
                const campaignReceipt = await this.utils.getTransactionReceiptMined(txHash);
                const campaignAddress = campaignReceipt && campaignReceipt.contractAddress;
                if (progressCallback) {
                    progressCallback('TwoKeyAcquisitionCampaignERC20', true, campaignAddress);
                }
                resolve(campaignAddress);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Inventory
    public async checkInventoryBalance(campaign: any): Promise<number> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            const hash = await promisify(campaignInstance.getAndUpdateInventoryBalance, [{from: this.base.address}]);
            await this.utils.getTransactionReceiptMined(hash);
            const balance = await promisify(campaignInstance.getInventoryBalance, []);
            return Promise.resolve(balance);
        } catch (err) {
            Promise.reject(err);
        }
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

    public async getReferrerCut(campaign: any): Promise<number> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            const cut = (await promisify(campaignInstance.getReferrerCut, [{from: this.base.address}])).toNumber() + 1;
            return Promise.resolve(cut);
        } catch (e) {
            Promise.reject(e);
        }
    }

    // Set Public Link
    public setAcquisitionPublicLinkKey(campaign: any, publicKey: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const gas = await promisify(campaignInstance.setPublicLinkKey.estimateGas, [publicKey, {from: this.base.address}]);
                await this.helpers._checkBalanceBeforeTransaction(gas, this.base._getGasPrice());
                const txHash = await promisify(campaignInstance.setPublicLinkKey, [publicKey, {
                    from: this.base.address,
                    gas,
                    gasPrice
                }]);
                await this.utils.getTransactionReceiptMined(txHash);
                resolve(publicKey);
            } catch (err) {
                reject(err);
            }
        });
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
                    const contractorAddress = await promisify(campaignInstance.getContractorAddress, []);
                    const {f_address, f_secret, p_message} = this.helpers._getUrlParams(referralLink);
                    const contractConstants = (await promisify(campaignInstance.getConstantInfo, []));
                    const decimals = contractConstants[3].toNumber();
                    console.log('Decimals', decimals);
                    const maxReferralRewardPercent = new BigNumber(contractConstants[1]).div(10 ** decimals).toNumber();
                    if (f_address === contractorAddress) {
                        resolve(maxReferralRewardPercent);
                        return;
                    }
                    const firstAddressInChain = p_message ? `0x${p_message.substring(0, 40)}` : f_address;
                    console.log('RefCHAIN', contractorAddress, f_address, firstAddressInChain);
                    let cuts: number[];
                    const firstPublicLink = await promisify(campaignInstance.publicLinkKey, [firstAddressInChain]);
                    if (firstAddressInChain === contractorAddress) {
                        console.log('First public Link', firstPublicLink);
                        cuts = Sign.validate_join(firstPublicLink, f_address, f_secret, p_message);
                    } else {
                        cuts = (await promisify(campaignInstance.getReferrerCuts, [firstAddressInChain])).map(cut => cut.toNumber());
                        cuts = cuts.concat(Sign.validate_join(firstPublicLink, f_address, f_secret, p_message));
                    }
                    console.log('CUTS', cuts, maxReferralRewardPercent);
                    const estimatedMaxReferrerRewardPercent = calcFromCuts(cuts, maxReferralRewardPercent);
                    resolve(estimatedMaxReferrerRewardPercent);
                }
            } catch (e) {
                reject(e);
            }
        });
    }

    public emitAcquisitionCampaignJoinEvent(campaignAddress: string, referralLink: string): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret} = this.helpers._getUrlParams(referralLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const from = this.base.eventsAddress;
                const txHash = await promisify(this.base.twoKeyEventContract.joined, [campaignAddress, f_address, this.base.address, {from}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    // Join Offchain
    public join(campaign: any, cut: number, referralLink?: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        const {public_address, private_key} = generatePublicMeta();
        return new Promise(async (resolve, reject) => {
            try {
                let new_message;
                console.log("referral link is : ===> " + referralLink);
                if (referralLink) {
                    const {f_address, f_secret, p_message} = this.helpers._getUrlParams(referralLink);
                    const campaignAddress = typeof (campaign) === 'string' ? campaign
                        : (await this.helpers._getAcquisitionCampaignInstance(campaign)).address;
                    const txHash = await this.emitAcquisitionCampaignJoinEvent(campaignAddress, referralLink);
                    console.log('JOIN EVENT', txHash);
                    console.log('New link for', this.base.address, f_address, f_secret, p_message);
                    new_message = Sign.free_join(this.base.address, public_address, f_address, f_secret, p_message, cut + 1);
                } else {
                    await this.setAcquisitionPublicLinkKey(campaign, `0x${public_address}`, gasPrice);
                }
                const raw = `f_address=${this.base.address}&f_secret=${private_key}&p_message=${new_message || ''}`;
                // const ipfsConnected = await this._checkIPFS();
                resolve(raw);
                // resolve('hash');
            } catch (err) {
                reject(err);
            }
        });
    }

    // ShortUrl
    public joinAndSetPublicLinkWithCut(campaignAddress: string, referralLink: string, cut?: number, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {f_address, f_secret, p_message} = this.helpers._getUrlParams(referralLink);
            if (!f_address || !f_secret) {
                reject('Broken Link');
            }
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaignAddress);
                let arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [this.base.address])).toString());
                const {public_address, private_key} = generatePublicMeta();

                if (!arcBalance) {
                    console.log('No Arcs', arcBalance, 'Call Free Join Take');
                    const signature = Sign.free_join_take(this.base.address, public_address, f_address, f_secret, p_message, cut + 1);
                    const gas = await promisify(campaignInstance.distributeArcsBasedOnSignature.estimateGas, [signature, {from: this.base.address}]);
                    console.log('Gas required for setPubLinkWithCut', gas);
                    await this.helpers._checkBalanceBeforeTransaction(gas, gasPrice);
                    // console.log(enough);
                    const txHash = await promisify(campaignInstance.distributeArcsBasedOnSignature, [signature, {
                        from: this.base.address,
                        gasPrice,
                        gas
                    }]);
                    console.log('setPubLinkWithCut', txHash);
                    await this.utils.getTransactionReceiptMined(txHash);
                    arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [this.base.address])).toString());
                }
                if (arcBalance) {
                    resolve(`f_address=${this.base.address}&f_secret=${private_key}&p_message=`)
                } else {
                    reject(new Error('Link is broken!'));
                }
            } catch (err) {
                reject(err);
            }
        });
    }

    // Send ARCS to other account
    public joinAndShareARC(campaignAddress: string, referralLink: string, recipient: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = this.helpers._getUrlParams(referralLink);
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
                    console.log('joinAndShareARC call Free Join Take');
                    const signature = Sign.free_join_take(this.base.address, public_address, f_address, f_secret, p_message);
                    console.log(signature, recipient);
                    const gas = await promisify(campaignInstance.joinAndShareARC.estimateGas, [signature, recipient, {from: this.base.address}]);
                    console.log('Gas for joinAndShareARC', gas);
                    await this.helpers._checkBalanceBeforeTransaction(gas, gasPrice);
                    const txHash = await promisify(campaignInstance.joinAndShareARC, [signature, recipient, {
                        from: this.base.address,
                        gasPrice
                    }]);
                    resolve(txHash);
                } else {
                    const gas = await promisify(campaignInstance.transfer.estimateGas, [recipient, 1, {from: this.base.address}]);
                    console.log('Gas for transfer ARC', gas);
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

    /* PARTICIPATE */
    public joinAndConvert(campaign: any, value: number | string | BigNumber, referralLink: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = this.helpers._getUrlParams(referralLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);

                const prevChain = await promisify(campaignInstance.received_from, [this.base.address]);
                // console.log('Previous referrer', prevChain, parseInt(prevChain, 16));
                //
                // const balance = parseFloat((await promisify(campaignInstance.balanceOf, [this.address])).toString());
                if (!parseInt(prevChain, 16)) {
                    console.log('No ARCS call Free Join Take');
                    const {public_address} = generatePublicMeta();
                    const signature = Sign.free_join_take(this.base.address, public_address, f_address, f_secret, p_message);
                    const gas = await promisify(campaignInstance.joinAndConvert.estimateGas, [signature, {
                        from: this.base.address,
                        value
                    }]);
                    console.log('Gas required for joinAndConvert', gas);
                    await this.helpers._checkBalanceBeforeTransaction(gas, gasPrice);
                    const txHash = await promisify(campaignInstance.joinAndConvert, [signature, {
                        from: this.base.address,
                        gasPrice,
                        gas,
                        value
                    }]);
                    await this.utils.getTransactionReceiptMined(txHash);
                    resolve(txHash);
                } else {
                    console.log('Previous referrer', prevChain, value);
                    // const gas = await promisify(campaignInstance.convert.estimateGas, [{from: this.base.address, value}]);
                    // console.log('Gas required for convert', gas);
                    // await this.helpers._checkBalanceBeforeTransaction(gas, gasPrice);
                    const txHash = await promisify(campaignInstance.convert, [{
                        from: this.base.address,
                        gasPrice,
                        value
                    }]);
                    // await this.utils.getTransactionReceiptMined(txHash);
                    // const conversions = await this.getAcquisitionConverterConversion(campaignInstance);
                    // console.log(conversions);
                    resolve(txHash);
                }
            } catch (e) {
                console.log('joinAndConvert ERROR', e.toString());
                reject(e);
            }
        });
    }

    public getAcquisitionConverterConversion(campaign: any, address: string = this.base.address): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.getTwoKeyConversionHandlerAddress, []);
                console.log('WhiteListsAddress', conversionHandler);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                const conversion = await promisify(conversionHandlerInstance.conversions, [this.base.address]);
                // const conversion = await promisify(campaignInstance.conversions, [address]);
                resolve(conversion);
            } catch (e) {
                reject(e);
            }
        })
    }

    public getTwoKeyConversionHandlerAddress(campaign: any) : Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.getTwoKeyConversionHandlerAddress, []);
                resolve(conversionHandler);
            } catch (e) {
                reject(e);
            }
        })
    }

    public getAssetContractData(campaign: any): Promise<any> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const assetContractData = await promisify(conversionHandlerInstance.getAssetContractData, []);
                // const assetContractData = await promisify(conversionHandlerInstance.getAssetContractData, []);
                console.log(assetContractData);
                resolve(assetContractData)
            } catch (e) {
                reject(e);
            }
        })
    }
}
