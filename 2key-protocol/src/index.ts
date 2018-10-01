import ipfsAPI from 'ipfs-api';
import {BigNumber} from 'bignumber.js';
import Web3 from 'web3';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import * as eth_wallet from 'ethereumjs-wallet';
import LZString from 'lz-string';
// import ethers from 'ethers';
import contractsMeta from './contracts';
import {
    EhtereumNetworks,
    ContractsAdressess,
    TwoKeyInit,
    BalanceMeta,
    BalanceNormalized,
    Transaction,
    TransactionReceipt,
    AcquisitionCampaign,
    Contract,
    RawTransaction,
    CreateCampignProgress,
    ContractEvent,
} from './interfaces';
import Sign from './sign';

export function promisify(func: any, args: any): Promise<any> {
    return new Promise((res, rej) => {
        func(...args, (err: any, data: any) => {
            if (err) return rej(err);
            return res(data);
        });
    });
}

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

// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
    ipfsIp: '192.168.47.100',
    ipfsPort: '5001',
    mainNetId: 3,
    syncTwoKeyNetId: 17,
    twoKeySyncUrl: 'http://192.168.47.100:18545'
};

const generatePublicMeta = (): { private_key: string, public_address: string } => {
    let pk = Sign.generatePrivateKey();
    let public_address = Sign.privateToPublic(pk);
    const private_key = pk.toString('hex');
    return {private_key, public_address};
};

export class TwoKeyProtocol {
    private readonly web3: any;
    private syncWeb3: any;
    private ipfs: any;
    private readonly address: string;
    private gasPrice: number;
    private totalSupply: number;
    private gas: number;
    private networks: EhtereumNetworks;
    private readonly contracts: ContractsAdressess;
    private twoKeyEconomy: any;
    private twoKeyEventContract: any;
    private twoKeyEvents: any;
    private eventsAddress: string;

    // private twoKeyReg: any;

    constructor(initValues: TwoKeyInit) {
        // init MainNet Client
        const {
            web3,
            address,
            eventsNetUrl = TwoKeyDefaults.twoKeySyncUrl,
            ipfsIp = TwoKeyDefaults.ipfsIp,
            ipfsPort = TwoKeyDefaults.ipfsPort,
            contracts,
            networks,
            reportKey = Sign.generatePrivateKey().toString('hex'),
        } = initValues;
        if (contracts) {
            this.contracts = contracts;
        } else if (networks) {
            this.networks = networks;
        } else {
            this.networks = {
                mainNetId: TwoKeyDefaults.mainNetId,
                syncTwoKeyNetId: TwoKeyDefaults.syncTwoKeyNetId,
            }
        }

        // init 2KeySyncNet Client
        const private_key = Buffer.from(reportKey, 'hex');
        const eventsWallet = eth_wallet.fromPrivateKey(private_key);

        const eventsEngine = new ProviderEngine();
        const eventsProvider = eventsNetUrl.startsWith('http') ? new RpcSubprovider({ rpcUrl: eventsNetUrl }) : new WSSubprovider({ rpcUrl: eventsNetUrl });
        eventsEngine.addProvider(new WalletSubprovider(eventsWallet, {}));
        eventsEngine.addProvider(eventsProvider);

        eventsEngine.start();
        this.syncWeb3 = new Web3(eventsEngine);
        this.eventsAddress = `0x${eventsWallet.getAddress().toString('hex')}`;
        this.twoKeyEventContract = this.syncWeb3.eth.contract(contractsMeta.TwoKeyPlasmaEvents.abi).at(contractsMeta.TwoKeyPlasmaEvents.networks[this.networks.syncTwoKeyNetId].address);

        if (!web3) {
            throw new Error('Web3 instance required!');
        }
        this.web3 = new Web3(web3.currentProvider);
        this.web3.eth.defaultBlock = 'pending';
        this.address = address;
        this.twoKeyEconomy = this.web3.eth.contract(contractsMeta.TwoKeyEconomy.abi).at(this._getContractDeployedAddress('TwoKeyEconomy'));
        this.ipfs = ipfsAPI(ipfsIp, ipfsPort, {protocol: 'http'});
    }

    public getGasPrice(): number {
        return this.gasPrice;
    }

    public getTotalSupply(): number {
        return this.totalSupply;
    }

    public getGas(): number {
        return this.gas;
    }

    public getAddress(): string {
        return this.address;
    }

    public getTransactionReceiptMined(txHash: string, web3: any = this.web3, interval: number = 500, timeout: number = 60000): Promise<TransactionReceipt> {
        return new Promise(async (resolve, reject) => {
            let txInterval;
            let fallbackTimeout = setTimeout(() => {
                if (txInterval) {
                    clearInterval(txInterval);
                    txInterval = null;
                }
                reject('Operation timeout');
            }, timeout);
            txInterval = setInterval(async () => {
                try {
                    const receipt = await promisify(web3.eth.getTransactionReceipt, [txHash]);
                    if (receipt) {
                        if (fallbackTimeout) {
                            clearTimeout(fallbackTimeout);
                            fallbackTimeout = null;
                        }
                        if (txInterval) {
                            clearInterval(txInterval);
                            txInterval = null;
                        }
                        resolve(receipt);
                    }
                } catch (e) {
                    if (fallbackTimeout) {
                        clearTimeout(fallbackTimeout);
                        fallbackTimeout = null;
                    }
                    if (txInterval) {
                        clearInterval(txInterval);
                        txInterval = null;
                    }
                    reject(e);
                }
            }, interval);
        });
    }

    public async ipfsAdd(data: any): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const dataString = JSON.stringify(data);
                console.log('Raw length', dataString.length);
                // const arr = LZString.compressToUint8Array(dataString);
                const compressed = LZString.compress(dataString);
                console.log('Compressed length', compressed.length);
                const hash = await promisify(this.ipfs.add, [[Buffer.from(compressed)]]);
                const pin = await promisify(this.ipfs.pin.add, [hash[0].hash]);
                resolve(pin[0].hash);
            } catch (e) {
                reject(e);
            }
        });
    }

    public getBalance(address: string = this.address, erc20address?: string): Promise<BalanceMeta> {
        const promises = [
            this._getEthBalance(address),
            this._getTokenBalance(address, erc20address),
            this._getTotalSupply(erc20address),
            this._getGasPrice()
        ];
        return new Promise(async (resolve, reject) => {
            try {
                const [eth, token, total, gasPrice] = await Promise.all(promises);
                resolve({
                    balance: {
                        ETH: eth,
                        '2KEY': token,
                        total
                    },
                    local_address: this.address,
                    gasPrice,
                });
            } catch (e) {
                reject(e);
            }
        });
    }

    public subscribe2KeyEvents(callback: (error: any, event: ContractEvent) => void) {
        this.twoKeyEvents = this.twoKeyEventContract.allEvents({fromBlock: 0, toBlock: 'pending'});
        this.twoKeyEvents.watch(callback);
    }

    public unsubscribe2KeyEvents() {
        this.twoKeyEvents.stopWatching();
    }

    /* TRANSFERS */

    public getERC20TransferGas(to: string, value: number | string | BigNumber): Promise<number> {
        this.gas = null;
        return new Promise(async (resolve, reject) => {
            try {
                this.gas = await promisify(this.twoKeyEconomy.transfer.estimateGas, [to, value, { from: this.address }]);
                resolve(this.gas);
            } catch (e) {
                reject(e);
            }
        });
    }

    public getETHTransferGas(to: string, value: number | string | BigNumber): Promise<number> {
        this.gas = null;
        return new Promise(async (resolve, reject) => {
            try {
                this.gas = await promisify(this.web3.eth.estimateGas, [{to, value, from: this.address }]);
                resolve(this.gas);
            } catch (e) {
                reject(e);
            }
        });
    }

    public async transfer2KEYTokens(to: string, value: number | string | BigNumber, gasPrice: number = this.gasPrice): Promise<string> {
        try {
            // const balance = parseFloat(this.fromWei(await this._getEthBalance(this.address)).toString());
            // const tokenBalance = await this._getTokenBalance(this.address);
            const gas = await this.getERC20TransferGas(to, value);
            // const etherRequired = parseFloat(this.fromWei(gasPrice * gas, 'ether').toString());
            // if (tokenBalance < value || balance < etherRequired) {
            //     Promise.reject(new Error(`Not enough founds on ${this.address}, required: [ETH: ${etherRequired}, 2KEY: ${value}], balance: [ETH: ${balance}, 2KEY: ${tokenBalance}]`));
            // }
            const params = {from: this.address, gas, gasPrice};
            // return this.twoKeyAdmin.transfer2KeyTokensTx(this.twoKeyEconomy.address, to, value).send(params);
            return promisify(this.twoKeyEconomy.transfer, [to, value, params]);
        } catch (err) {
            Promise.reject(err);
        }
    }

    public transferEther(to: string, value: number | string | BigNumber, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                // const balance = parseFloat(this.fromWei(await this._getEthBalance(this.address)).toString());
                const gas = await this.getETHTransferGas(to, value);
                // const totalValue = value + parseFloat(this.fromWei(gasPrice * gas, 'ether').toString());
                // if (totalValue > balance) {
                //     Promise.reject(new Error(`Not enough founds on ${this.address} required ${value}, balance: ${balance}`));
                // }
                const params = {
                    to,
                    gasPrice,
                    gas,
                    value,
                    from: this.address
                };
                const txHash = await promisify(this.web3.eth.sendTransaction, [params]);
                resolve(txHash);
            } catch (err) {
                reject(err);
            }
        });
    }

    /* ACQUISITION CAMPAIGN */

    public estimateAcquisitionCampaign(data: AcquisitionCampaign): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const {public_address} = generatePublicMeta();
                const predeployGas = await this._estimateSubcontractGas(contractsMeta.TwoKeyWhitelisted);
                const campaignGas = await this._estimateSubcontractGas(contractsMeta.TwoKeyAcquisitionCampaignERC20, [
                    this._getContractDeployedAddress('TwoKeyEventSource'),
                    this.twoKeyEconomy.address,
                    // Fake WhiteListInfluence address
                    `0x${public_address}`,
                    // Fake WhiteListConverter address
                    data.moderator || this.address,
                    data.assetContractERC20,
                    data.campaignStartTime / 1000,
                    data.campaignEndTime / 1000,
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
    public createAcquisitionCampaign(data: AcquisitionCampaign, progressCallback?: CreateCampignProgress, gasPrice?: number): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                // const gasRequired = await this.estimateAcquisitionCampaign(data);
                // await this._checkBalanceBeforeTransaction(gasRequired, gasPrice || this.gasPrice);
                let txHash = await this._createContract(contractsMeta.TwoKeyWhitelisted, gasPrice, null, progressCallback);
                const predeployReceipt = await this.getTransactionReceiptMined(txHash);
                const whitelistsAddress = predeployReceipt && predeployReceipt.contractAddress;
                if (progressCallback) {
                    progressCallback('TwoKeyWhitelisted', true, whitelistsAddress);
                }
                // const whitelistsInstance = this.web3.eth.contract(contractsMeta.TwoKeyWhitelisted.abi).at(whitelistsAddress);

                txHash = await this._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20, gasPrice, [
                    this._getContractDeployedAddress('TwoKeyEventSource'),
                    this.twoKeyEconomy.address,
                    whitelistsAddress,
                    data.moderator || this.address,
                    data.assetContractERC20,
                    data.campaignStartTime / 1000,
                    data.campaignEndTime / 1000,
                    data.expiryConversion,
                    data.moderatorFeePercentageWei,
                    data.maxReferralRewardPercentWei,
                    data.maxConverterBonusPercentWei,
                    data.pricePerUnitInETHWei,
                    data.minContributionETHWei,
                    data.maxContributionETHWei,
                    data.referrerQuota || 5,
                ], progressCallback);
                const campaignReceipt = await this.getTransactionReceiptMined(txHash);
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
    public async checkAndUpdateAcquisitionInventoryBalance(campaign: any): Promise<number> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const hash = await promisify(campaignInstance.getAndUpdateInventoryBalance, [{from: this.address}]);
            await this.getTransactionReceiptMined(hash);
            const balance = await promisify(campaignInstance.getInventoryBalance, []);
            return Promise.resolve(balance);
        } catch (err) {
            Promise.reject(err);
        }
    }

    // Get Public Link
    public async getAcquisitionPublicLinkKey(campaign: any, address: string = this.address): Promise<string> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const publicLink = await promisify(campaignInstance.publicLinkKey, [address]);
            return Promise.resolve(publicLink);

        } catch (e) {
            Promise.reject(e)
        }
    }

    public async getAcquisitionReferrerCut(campaign: any): Promise<number> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const cut = (await promisify(campaignInstance.getReferrerCut, [{from: this.address}])).toNumber() + 1;
            return Promise.resolve(cut);
        } catch (e) {
            Promise.reject(e);
        }
    }

    // Set Public Link
    public setAcquisitionPublicLinkKey(campaign: any, publicKey: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
                const gas = await promisify(campaignInstance.setPublicLinkKey.estimateGas, [publicKey, {from: this.address}]);
                await this._checkBalanceBeforeTransaction(gas, this.gasPrice);
                const txHash = await promisify(campaignInstance.setPublicLinkKey, [publicKey, {
                    from: this.address,
                    gas,
                    gasPrice
                }]);
                await this.getTransactionReceiptMined(txHash);
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
                    const cut = await this.getAcquisitionReferrerCut(campaign);
                    resolve(cut);
                } else {
                    const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
                    const contractorAddress = await promisify(campaignInstance.getContractorAddress, []);
                    const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
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
                const {f_address, f_secret } = this._getUrlParams(referralLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const from = this.eventsAddress;
                const txHash = await promisify(this.twoKeyEventContract.joined, [campaignAddress, f_address, this.address, { from }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    // Join Offchain
    public joinAcquisitionCampaign(campaign: any, cut: number, referralLink?: string, gasPrice: number = this.gasPrice): Promise<string> {
        const {public_address, private_key} = generatePublicMeta();
        return new Promise(async (resolve, reject) => {
            try {
                let new_message;
                if (referralLink) {
                    const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
                    const campaignAddress = typeof (campaign) === 'string' ? campaign
                        : (await this._getAcquisitionCampaignInstance(campaign)).address;
                    const txHash = await this.emitAcquisitionCampaignJoinEvent(campaignAddress, referralLink);
                    console.log('JOIN EVENT', txHash);
                    console.log('New link for', this.address, f_address, f_secret, p_message);
                    new_message = Sign.free_join(this.address, public_address, f_address, f_secret, p_message, cut + 1);
                } else {
                    await this.setAcquisitionPublicLinkKey(campaign, `0x${public_address}`, gasPrice);
                }
                const raw = `f_address=${this.address}&f_secret=${private_key}&p_message=${new_message || ''}`;
                // const ipfsConnected = await this._checkIPFS();
                resolve(raw);
                // resolve('hash');
            } catch (err) {
                reject(err);
            }
        });
    }

    // ShortUrl
    public joinAcquisitionCampaignAndSetPublicLinkWithCut(campaignAddress: string, referralLink: string, cut?: number, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
            if (!f_address || !f_secret) {
                reject('Broken Link');
            }
            try {
                const campaignInstance = await this._getAcquisitionCampaignInstance(campaignAddress);
                let arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [this.address])).toString());
                const {public_address, private_key} = generatePublicMeta();

                if (!arcBalance) {
                    console.log('No Arcs', arcBalance, 'Call Free Join Take');
                    const signature = Sign.free_join_take(this.address, public_address, f_address, f_secret, p_message, cut + 1);
                    const gas = await promisify(campaignInstance.distributeArcsBasedOnSignature.estimateGas, [signature, {from: this.address}]);
                    console.log('Gas required for setPubLinkWithCut', gas);
                    await this._checkBalanceBeforeTransaction(gas, gasPrice);
                    // console.log(enough);
                    const txHash = await promisify(campaignInstance.distributeArcsBasedOnSignature, [signature, {
                        from: this.address,
                        gasPrice,
                        gas
                    }]);
                    console.log('setPubLinkWithCut', txHash);
                    await this.getTransactionReceiptMined(txHash);
                    arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [this.address])).toString());
                }
                if (arcBalance) {
                    resolve(`f_address=${this.address}&f_secret=${private_key}&p_message=`)
                } else {
                    reject(new Error('Link is broken!'));
                }
            } catch (err) {
                reject(err);
            }
        });
    }

    // Send ARCS to other account
    public joinAcquisitionCampaignAndShareARC(campaignAddress: string, referralLink: string, recipient: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const campaignInstance = await this._getAcquisitionCampaignInstance(campaignAddress);
                const arcBalance = parseFloat((await promisify(campaignInstance.balanceOf, [this.address])).toString());
                const prevChain = await promisify(campaignInstance.received_from, [recipient]);
                if (parseInt(prevChain, 16)) {
                    reject(new Error('User already in chain'));
                }

                if (!arcBalance) {
                    const {public_address} = generatePublicMeta();
                    console.log('joinAcquisitionCampaignAndShareARC call Free Join Take');
                    const signature = Sign.free_join_take(this.address, public_address, f_address, f_secret, p_message);
                    console.log(signature, recipient);
                    const gas = await promisify(campaignInstance.joinAndShareARC.estimateGas, [signature, recipient, {from: this.address}]);
                    console.log('Gas for joinAndShareARC', gas);
                    await this._checkBalanceBeforeTransaction(gas, gasPrice);
                    const txHash = await promisify(campaignInstance.joinAndShareARC, [signature, recipient, {
                        from: this.address,
                        gasPrice
                    }]);
                    resolve(txHash);
                } else {
                    const gas = await promisify(campaignInstance.transfer.estimateGas, [recipient, 1, {from: this.address}]);
                    console.log('Gas for transfer ARC', gas);
                    const txHash = await promisify(campaignInstance.transfer, [recipient, 1, {
                        from: this.address,
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
    public joinAcquisitionCampaignAndConvert(campaign: any, value: number | string | BigNumber, referralLink: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
            if (!f_address || !f_secret) {
                reject('Broken Link');
            }
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);

            const prevChain = await promisify(campaignInstance.received_from, [this.address]);
            // console.log('Previous referrer', prevChain, parseInt(prevChain, 16));
            //
            // const balance = parseFloat((await promisify(campaignInstance.balanceOf, [this.address])).toString());
            if (!parseInt(prevChain, 16)) {
                console.log('No ARCS call Free Join Take');
                const {public_address} = generatePublicMeta();
                const signature = Sign.free_join_take(this.address, public_address, f_address, f_secret, p_message);
                const gas = await promisify(campaignInstance.joinAndConvert.estimateGas, [signature, {
                    from: this.address,
                    value
                }]);
                console.log('Gas required for joinAndConvert', gas);
                await this._checkBalanceBeforeTransaction(gas, gasPrice);
                const txHash = await promisify(campaignInstance.joinAndConvert, [signature, {
                    from: this.address,
                    gasPrice,
                    gas,
                    value
                }]);
                await this.getTransactionReceiptMined(txHash);
                resolve(txHash);
            } else {
                console.log('Previous referrer', prevChain, value);
                const gas = await promisify(campaignInstance.convert.estimateGas, [{from: this.address, value}]);
                console.log('Gas required for convert', gas);
                await this._checkBalanceBeforeTransaction(gas, gasPrice);
                const txHash = await promisify(campaignInstance.convert, [{from: this.address, gasPrice, gas, value}]);
                await this.getTransactionReceiptMined(txHash);
                const conversions = await this.getAquisitionConverterConversion(campaignInstance);
                console.log(conversions);
                resolve(txHash);
            }
        });
    }

    public getAquisitionConverterConversion(campaign: any, address: string = this.address): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
                const whitelistsAddress = await promisify(campaignInstance.getAddressOfWhitelisted, []);
                console.log('WhiteListsAddress', whitelistsAddress);
                const whitelistsInstance = this.web3.eth.contract(contractsMeta.TwoKeyWhitelisted.abi).at(whitelistsAddress);
                const conversion = await promisify(whitelistsInstance.conversions, [this.address]);
                // const conversion = await promisify(campaignInstance.conversions, [address]);
                resolve(conversion);
            } catch (e) {
                reject(e);
            }
        })
    }

    /* UTILS */

    public fromWei(number: number | string | BigNumber, unit?: string): string | BigNumber {
        const result = this.web3.fromWei(number, unit);
        return result;
    }

    public toWei(number: string | number | BigNumber, unit?: string): BigNumber {
        return this.web3.toWei(number, unit);
    }

    public toHex(data: any): string {
        return this.web3.toHex(data);
    }

    public getBalanceOfArcs(campaign: any, address: string = this.address): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
                const balance = (await promisify(campaignInstance.balanceOf, [address])).toNumber();
                resolve(balance);
            } catch (e) {
                reject(e);
            }
        });
    }

    public balanceFromWeiString(meta: BalanceMeta, inWei: boolean = false, toNum: boolean = false): BalanceNormalized {
        return {
            balance: {
                ETH: toNum ? this._normalizeNumber(meta.balance.ETH, inWei) : this._normalizeString(meta.balance.ETH, inWei),
                '2KEY': toNum ? this._normalizeNumber(meta.balance['2KEY'], inWei) : this._normalizeString(meta.balance['2KEY'], inWei),
                total: toNum ? this._normalizeNumber(meta.balance.total, inWei) : this._normalizeString(meta.balance.total, inWei)
            },
            local_address: meta.local_address,
            // gasPrice: toNum ? this._normalizeNumber(meta.gasPrice, inWei) : this._normalizeString(meta.gasPrice, inWei),
            gasPrice: toNum ? this._normalizeNumber(meta.gasPrice, false) : this._normalizeString(meta.gasPrice, false),
        }
    }

    private _normalizeString(value: number | string | BigNumber, inWei: boolean): string {
        return parseFloat(inWei ? this.fromWei(value, 'ether').toString() : value.toString()).toString();
    }

    private _normalizeNumber(value: number | string | BigNumber, inWei: boolean): number {
        return parseFloat(inWei ? this.fromWei(value, 'ether').toString() : value.toString());
    }

    private _getContractDeployedAddress(contract: string): string {
        return this.contracts ? this.contracts[contract] : contractsMeta[contract].networks[this.networks.mainNetId].address
    }

    private _getGasPrice(): Promise<number | string | BigNumber> {
        return new Promise(async (resolve, reject) => {
            try {
                const gasPrice = await promisify(this.web3.eth.getGasPrice, []);
                this.gasPrice = gasPrice.toNumber();
                resolve(gasPrice);
            } catch (e) {
                reject(e);
            }
        });
    }

    private _getEthBalance(address: string): Promise<number | string | BigNumber> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await promisify(this.web3.eth.getBalance, [address, this.web3.eth.defaultBlock]));
            } catch (e) {
                reject(e);
            }
        })
    }

    private _getTokenBalance(address: string, erc20address: string = this.twoKeyEconomy.address): Promise<number | string | BigNumber> {
        return new Promise(async (resolve, reject) => {
            try {
                const erc20 = await this._createAndValidate('ERC20', erc20address);
                const balance = await promisify(erc20.balanceOf, [address]);

                resolve(balance);
            } catch (e) {
                reject(e);
            }
        });
    }

    private _getTotalSupply(erc20address: string = this.twoKeyEconomy.address): Promise<number | string | BigNumber> {
        return new Promise(async (resolve, reject) => {
            try {
                const erc20 = await this._createAndValidate('ERC20', erc20address);
                this.totalSupply = await promisify(erc20.totalSupply, []);
                resolve(this.totalSupply);
            } catch (e) {
                reject(e);
            }
        });
    }

    public _getTransaction(txHash: string): Promise<Transaction> {
        return new Promise((resolve, reject) => {
            this.web3.eth.getTransaction(txHash, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(res);
                }
            });
        });
    }

    private _createContract(contract: Contract, gasPrice: number = this.gasPrice, params?: any[], progressCallback?: CreateCampignProgress): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {abi, bytecode: data, name} = contract;
            const gas = await this._estimateSubcontractGas(contract, params);
            const createParams = params ? [...params, {data, from: this.address, gas, gasPrice}] : [{
                data,
                from: this.address,
                gas,
                gasPrice
            }];
            this.web3.eth.contract(abi).new(...createParams, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    if (res.address) {
                        if (progressCallback) {
                            progressCallback(name, true, res.address);
                        }
                        resolve(res.address);
                    } else if (progressCallback) {
                        progressCallback(name, false, res.transactionHash);
                        resolve(res.transactionHash);
                    }
                }
            });
        });
    }

    private _estimateSubcontractGas(contract: Contract, params?: any[]): Promise<number> {
        return new Promise(async (resolve, reject) => {
            const {abi, bytecode: data} = contract;
            const estimateParams = params ? [...params, {data, from: this.address}] : [{data, from: this.address}];
            this.web3.eth.estimateGas({
                data: this.web3.eth.contract(abi).new.getData(...estimateParams),
            }, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(res);
                }
            })
        });
    }

    private _estimateTransactionGas(data: RawTransaction): Promise<number> {
        return new Promise((resolve, reject) => {
            this.web3.eth.estimateGas(data, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(res);
                }
            });
        });
    }

    // private _getNonce(): Promise<number> {
    //     return new Promise((resolve, reject) => {
    //         this.web3.eth.getTransactionCount(this.address, 'pending', (err, res) => {
    //             if (err) {
    //                 reject(err);
    //             } else {
    //                 // console.log('NONCE', res, this.address);
    //                 resolve(res);
    //             }
    //         });
    //     });
    // }

    // private _getBlock(block: string | number): Promise<Transaction> {
    //     return new Promise((resolve, reject) => {
    //         this.web3.eth.getBlock(block, (err, res) => {
    //             if (err) {
    //                 reject(err);
    //             } else {
    //                 resolve(res);
    //             }
    //         });
    //     });
    // }

    private _getUrlParams(url: string): any {
        let hashes = url.slice(url.indexOf('?') + 1).split('&');
        let params = {};
        hashes.map(hash => {
            let [key, val] = hash.split('=');
            params[key] = decodeURIComponent(val);
        });
        return params;
    }

    private async _checkBalanceBeforeTransaction(gasRequired: number, gasPrice: number): Promise<boolean> {
        if (!this.gasPrice) {
            await this._getGasPrice();
        }
        const balance = this.fromWei(await this._getEthBalance(this.address), 'ether');
        const transactionFee = this.fromWei((gasPrice || this.gasPrice) * gasRequired, 'ether');
        console.log(`_checkBalanceBeforeTransaction ${this.address}, ${balance} (${transactionFee}), gasPrice: ${(gasPrice || this.gasPrice)}`);
        if (transactionFee > balance) {
            throw new Error(`Not enough founds. Required: ${transactionFee}. Your balance: ${balance},`);
        }
        return true;
    }

    private async _getAcquisitionCampaignInstance(campaign: any) {
        return campaign.address
            ? campaign
            : await this._createAndValidate('TwoKeyAcquisitionCampaignERC20', campaign);
    }

    private async _createAndValidate(
        contractName: string,
        address: string
    ): Promise<any> {
        const code = await promisify(this.web3.eth.getCode, [address]);

        // in case of missing smartcontract, code can be equal to "0x0" or "0x" depending on exact web3 implementation
        // to cover all these cases we just check against the source code length — there won't be any meaningful EVM program in less then 3 chars
        if (code.length < 4 || !contractsMeta[contractName]) {
            throw new Error(`Contract at ${address} doesn't exist!`);
        }
        return this.web3.eth.contract(contractsMeta[contractName].abi).at(address);
    }

    private _checkIPFS(): Promise<boolean> {
        return new Promise<boolean>(async (resolve, reject) => {
            try {
                const ipfs = await promisify(this.ipfs.id, []);
                resolve(Boolean(ipfs && ipfs.id));
            } catch (e) {
                reject(e);
            }
        });
    }
}
