import {IERC20, IOffchainData, ITwoKeyBase, ITwoKeyHelpers, ITwoKeyUtils, ICreateOpts } from '../interfaces';
import {
    IAcquisitionCampaign,
    IAcquisitionCampaignMeta,
    ITokenAmount,
    IJoinLinkOpts,
    IPublicLinkKey,
    IPublicLinkOpts,
    ITwoKeyAcquisitionCampaign,
} from './interfaces';

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

    /* ACQUISITION CAMPAIGN */

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
                    this.base.twoKeyEconomy.address,
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

    // Create Campaign
    public create(data: IAcquisitionCampaign, from: string, { progressCallback, gasPrice, interval, timeout = 60000 }: ICreateOpts = {}): Promise<IAcquisitionCampaignMeta> {
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
                    txHash = await this.helpers._createContract(contractsMeta.TwoKeyConversionHandler, from, { gasPrice, params: [data.tokenDistributionDate, data.maxDistributionDateShiftInDays, data.bonusTokensVestingMonths, data.bonusTokensVestingStartShiftInDaysFromDistributionDate], progressCallback});
                    const predeployReceipt = await this.utils.getTransactionReceiptMined(txHash,{ web3: this.base.web3, interval, timeout});
                    if (predeployReceipt.status !== '0x1') {
                        reject(predeployReceipt);
                        return;
                    }
                    conversionHandlerAddress = predeployReceipt && predeployReceipt.contractAddress;
                    if (progressCallback) {
                        progressCallback('TwoKeyConversionHandler', true, conversionHandlerAddress);
                    }
                }
                // const whitelistsInstance = this.web3.eth.contract(contractsMeta.TwoKeyWhitelisted.abi).at(whitelistsAddress);

                txHash = await this.helpers._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20, from, {
                    gasPrice,
                    params: [
                        this.helpers._getContractDeployedAddress('TwoKeyEventSource'),
                        this.base.twoKeyEconomy.address,
                        conversionHandlerAddress,
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
                    ],
                    progressCallback,
                    link: {
                        name: 'Call',
                        address: this.base.twoKeyCall.address,
                    },
                });
                const campaignReceipt = await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.web3, interval, timeout});
                if (campaignReceipt.status !== '0x1') {
                    reject(campaignReceipt);
                    return;
                }
                const campaignAddress = campaignReceipt && campaignReceipt.contractAddress;
                if (progressCallback) {
                    progressCallback('TwoKeyAcquisitionCampaignERC20', true, campaignAddress);
                }
                console.log('Campaign created', campaignAddress);
                const campaignPublicLinkKey = await this.join(campaignAddress, from, {gasPrice});
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

    public getPublicMeta(campaign: any, from?: string): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                // const contractor = await promisify(campaignInstance.getContractorAddress, []);
                // const ipfsHash = await promisify(campaignInstance.publicMetaHash, []);
                const isAddressJoined = await this.isAddressJoined(campaignInstance, from);
                const ipfsHash = await promisify(campaignInstance.publicMetaHash, []);
                const meta = JSON.parse((await promisify(this.base.ipfs.cat, [ipfsHash])).toString());
                resolve({meta, isAddressJoined});
            } catch (e) {
                reject(e);
            }
        });
    }

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

    // Inventory
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

    public async checkInventoryBalance(campaign: any, from: string): Promise<number | string | BigNumber> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            const nonce = await this.helpers._getNonce(from);
            const hash = await promisify(campaignInstance.getAndUpdateInventoryBalance, [{from, nonce}]);
            await this.utils.getTransactionReceiptMined(hash);
            const balance = await promisify(campaignInstance.getInventoryBalance, [{from}]);
            return Promise.resolve(balance);
        } catch (err) {
            Promise.reject(err);
        }
    }

    public async getReferrerCut(campaign: any, from: string): Promise<number> {
        try {
            const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
            const cut = (await promisify(campaignInstance.getReferrerCut, [{from}])).toNumber() + 1;
            return Promise.resolve(cut);
        } catch (e) {
            Promise.reject(e);
        }
    }

    // Estimate referral maximum reward
    public getEstimatedMaximumReferralReward(campaign: any, from: string, referralLink: string): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                if (!referralLink) {
                    const cut = await this.getReferrerCut(campaign, from);
                    resolve(cut);
                } else {
                    const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                    const contractorAddress = await promisify(campaignInstance.getContractorAddress, []);
                    const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    const contractConstants = (await promisify(campaignInstance.getConstantInfo, []));
                    const decimals = contractConstants[3].toNumber();
                    this.base._log('Decimals', decimals);
                    this.base._log('getEstimatedMaximumReferralReward', f_address, contractorAddress);
                    const maxReferralRewardPercent = new BigNumber(contractConstants[1]).div(10 ** decimals).toNumber();
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

    // Visit link
    public visit(campaignAddress: string, referralLink: string): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                const sig = Sign.free_take(this.base.plasmaAddress, f_address, f_secret, p_message);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaignAddress);
                const contractor = await promisify(campaignInstance.getContractorAddress, []);
                const txHash: string = await promisify(this.base.twoKeyPlasmaEvents.visited, [
                    campaignAddress,
                    contractor,
                    sig,
                    {from: this.base.plasmaAddress, gasPrice: 0}
                ]);
                await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.plasmaWeb3});
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    // Set Public Link
    public setPublicLinkKey(campaign: any, from: string, publicLink: string, { cut, gasPrice = this.base._getGasPrice() }: IPublicLinkOpts = {}): Promise<IPublicLinkKey> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const nonce = await this.helpers._getNonce(from);
                const contractor = await promisify(campaignInstance.getContractorAddress, [{from, nonce}]);
                this.base._log('SETPUBLICLINK CONTRACTOR', contractor, publicLink);
                const [mainTxHash, plasmaTxHash] = await Promise.all([
                    promisify(campaignInstance.setPublicLinkKey, [publicLink, {
                        from,
                        gasPrice,
                    }]),
                    promisify(this.base.twoKeyPlasmaEvents.setPublicLinkKey, [campaignInstance.address,
                        contractor, from, publicLink, {from: this.base.plasmaAddress, gasPrice: 0}
                    ]),
                ]);
                console.log('>>>PLASMADEBUG', campaignInstance.address, contractor, from, publicLink,  {from: this.base.plasmaAddress, gasPrice: 0});
                await Promise.all([this.utils.getTransactionReceiptMined(mainTxHash), this.utils.getTransactionReceiptMined(plasmaTxHash, {web3: this.base.plasmaWeb3})]);
                if (cut > -1) {
                    await promisify(campaignInstance.setCut, [cut, {from}]);
                }
                resolve({publicLink, contractor});
            } catch (err) {
                reject(err);
            }
        });
    }

    // Get Public Link
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
    public join(campaign: any, from: string, { cut, gasPrice = this.base._getGasPrice(), referralLink, cutSign }: IJoinLinkOpts = {}): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignAddress = typeof (campaign) === 'string' ? campaign
                    : (await this.helpers._getAcquisitionCampaignInstance(campaign)).address;

                // if (from !== this.base.plasmaAddress) {
                const sig = await Sign.sign_plasma2eteherum(this.base.plasmaAddress, from, this.base.web3);
                this.base._log('Signature', sig, from, this.base.plasmaAddress);
                const txHash: string = await promisify(this.base.twoKeyPlasmaEvents.add_plasma2ethereum, [sig, {
                    from: this.base.plasmaAddress,
                    gasPrice: 0
                }]);
                await this.utils.getTransactionReceiptMined(txHash, {web3: this.base.plasmaWeb3, timeout: 300000});
                const stored_ethereum_address = await promisify(this.base.twoKeyPlasmaEvents.plasma2ethereum, [this.base.plasmaAddress]);
                if (stored_ethereum_address !== from) {
                    reject(stored_ethereum_address + ' != ' + from)
                }
                // }
                // const {public_address, private_key} = await Sign.generateSignatureKeys(from, this.base.plasmaAddress, campaignAddress, this.base.web3);

                const private_key = this.base.web3.sha3(sig).slice(2, 2 + 32 * 2);
                const public_address = Sign.privateToPublic(Buffer.from(private_key, 'hex'));

                let new_message;
                let contractor;
                if (referralLink) {
                    const {f_address, f_secret, p_message, contractor: campaignContractor} = await this.utils.getOffchainDataFromIPFSHash(referralLink);
                    contractor = campaignContractor;
                    this.base._log('New link for', from, f_address, f_secret, p_message);
                    this.base._log('P_MESSAGE', p_message);
                    new_message = Sign.free_join(from, public_address, f_address, f_secret, p_message, cut + 1, cutSign);
                } else {
                    const {contractor: campaignContractor} = await this.setPublicLinkKey(campaign, from, `0x${public_address}`, {cut, gasPrice});
                    contractor = campaignContractor;
                }
                const linkObject: IOffchainData = {
                    campaign: campaignAddress,
                    contractor,
                    f_address: from,
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
                    const {public_address} = generatePublicMeta();
                    const signature = Sign.free_join_take(from, public_address, f_address, f_secret, p_message);
                    const txHash: string = await promisify(campaignInstance.joinAndConvert, [signature, {
                        from,
                        gasPrice,
                        value,
                        nonce,
                    }]);
                    await this.utils.getTransactionReceiptMined(txHash);
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
                reject(e);
            }
        });
    }

    // Send ARCS to other account
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

    public getConverterConversion(campaign: any, from: string): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const conversionHandler = await promisify(campaignInstance.getTwoKeyConversionHandlerAddress, [{from}]);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandler);
                const conversion = await promisify(conversionHandlerInstance.conversions, [from]);
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
                const conversionHandler = await promisify(campaignInstance.getTwoKeyConversionHandlerAddress, []);
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

    public approveConverter(campaign: any, converter: string, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash: string = await promisify(conversionHandlerInstance.approveConverter, [converter, {from, gasPrice, nonce}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    public rejectConverter(campaign: any, converter: string, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash: string = await promisify(conversionHandlerInstance.rejectConverter, [converter, {from, gasPrice, nonce}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    public cancelConverter(campaign: any, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contractsMeta.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const txHash: string = await promisify(conversionHandlerInstance.cancelConverter, [{from, gasPrice, nonce}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

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

    public executeConversion(campaign: any, converter: string, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const conversionHandlerAddress = await this.getTwoKeyConversionHandlerAddress(campaign);
                const conversionHandlerInstance = this.base.web3.eth.contract(contracts.TwoKeyConversionHandler.abi).at(conversionHandlerAddress);
                const nonce = await this.helpers._getNonce(from);
                const txHash: string = await promisify(conversionHandlerInstance.executeConversion, [converter, {from, gasPrice, nonce}]);
                this.base._log(txHash);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

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

    public addFungibleAssetsToInventoryOfCampaign(campaign: any, amount: number, from: string, gasPrice: number = this.base._getGasPrice()) : Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const nonce = await this.helpers._getNonce(from);
                const txHash: string = await promisify(campaignInstance.addUnitsToInventory, [amount, {from, gasPrice, nonce}]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        })
    }

    public cancel(campaign: any, from: string, gasPrice: number = this.base._getGasPrice()): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const txHash: string = await promisify(campaignInstance.cancel,[{from, gasPrice, nonce}]);
                resolve(txHash);
            } catch(e) {
                reject(e);
            }
        })
    }
}
