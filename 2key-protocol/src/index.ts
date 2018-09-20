import ipfsAPI from 'ipfs-api';
import {BigNumber} from 'bignumber.js';
import LZString from 'lz-string';
import contractsMeta from './contracts';
import {
    EhtereumNetworks,
    ContractsAdressess,
    TwoKeyInit,
    BalanceMeta,
    Transaction,
    TransactionReceipt,
    AcquisitionCampaign,
    Contract,
    RawTransaction,
    CreateCampignProgress,
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

function getTransactionReceiptMined(txHash: string | string[], interval: number = 500, timeout: number = 60000): Promise<TransactionReceipt | TransactionReceipt[]> {
    const self = this;
    let fallback;
    const transactionReceiptAsync = function(resolve, reject) {
        if (!fallback) {
            setTimeout(() => {
               reject('Timed out');
            }, timeout);
        }
        self.getTransactionReceipt(txHash, (error, receipt) => {
            if (error) {
                if (fallback) {
                    clearTimeout(fallback);
                    fallback = null;
                }
                reject(error);
            } else if (receipt == null) {
                setTimeout(
                    () => transactionReceiptAsync(resolve, reject),
                    interval);
            } else {
                if (fallback) {
                    clearTimeout(fallback);
                    fallback = null;
                }
                resolve(receipt);
            }
        });
    };

    if (Array.isArray(txHash)) {
        return Promise.all(txHash.map(
            oneTxHash => self.getTransactionReceiptMined(oneTxHash, interval)));
    } else if (typeof txHash === "string") {
        return new Promise(transactionReceiptAsync);
    } else {
        throw new Error("Invalid Type: " + txHash);
    }
};

// const contracts = require('./contracts.json');
// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
    ipfsIp: '192.168.47.100',
    ipfsPort: '5001',
    mainNetId: 4,
    syncTwoKeyNetId: 17,
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
    // private twoKeyReg: any;

    constructor(initValues: TwoKeyInit) {
        // init MainNet Client
        const {
            web3,
            // syncUrl = TwoKeyDefaults.twoKeySyncUrl,
            ipfsIp = TwoKeyDefaults.ipfsIp,
            ipfsPort = TwoKeyDefaults.ipfsPort,
            contracts,
            networks,
        } = initValues;
        if (!web3) {
            throw new Error('Web3 instance required!');
        }
        if (!web3.eth.defaultAccount) {
            throw new Error('defaultAccount required!');
        }
        this.web3 = web3;
        this.web3.eth.defaultBlock = 'pending';
        this.address = this.web3.eth.defaultAccount;
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
        this.web3.eth.defaultBlock = 'pending';
        this.web3.eth.getTransactionReceiptMined = getTransactionReceiptMined;
        this.twoKeyEconomy = this.web3.eth.contract(contractsMeta.TwoKeyEconomy.abi).at(this._getContractDeployedAddress('TwoKeyEconomy'));
        // this.twoKeyReg = this.web3.eth.contract(solidityContracts.TwoKeyReg.abi).at(this._getContractDeployedAddress('TwoKeyReg'));

        // init 2KeySyncNet Client
        // const syncEngine = new ProviderEngine();
        // this.syncWeb3 = new Web3(syncEngine);
        // const syncProvider = new WSSubprovider({ rpcUrl: syncUrl });
        // syncEngine.addProvider(syncProvider);
        // syncEngine.start();
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

    public getTransactionReceiptMined(txHash: string | string[], interval?: number, timeout?: number): Promise<TransactionReceipt | TransactionReceipt[]> {
        return this.web3.eth.getTransactionReceiptMined(txHash, interval, timeout);
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
        return new Promise((resolve, reject) => {
            Promise.all(promises)
                .then(([eth, token, total, gasPrice]) => {
                    resolve({
                        balance: {
                            ETH: eth,
                            total: total,
                            '2KEY': token,
                        },
                        local_address: this.address,
                        gasPrice: gasPrice,
                    });
                })
                .catch(reject)
        });
    }

    /* TRANSFERS */

    public getERC20TransferGas(to: string, value: number): Promise<number> {
        this.gas = null;
        return new Promise((resolve, reject) => {
            this.twoKeyEconomy.transfer.estimateGas(to, this.toWei(value, 'ether'), { from: this.address }, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    this.gas = res;
                    resolve(this.gas);
                }
            });
        });
    }

    public getETHTransferGas(to: string, value: number): Promise<number> {
        this.gas = null;
        return new Promise((resolve, reject) => {
            this.web3.eth.estimateGas({ to, value: this.toWei(value, 'ether').toString() }, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    this.gas = res;
                    resolve(this.gas);
                }
            });
        });
    }

    public async transfer2KEYTokens(to: string, value: number, gasPrice: number = this.gasPrice): Promise<string> {
        try {
            const balance = await this._getEthBalance(this.address);
            const tokenBalance = await this._getTokenBalance(this.address);
            const gasRequired = await this.getERC20TransferGas(to, value);
            const etherRequired = this.fromWei(gasPrice * gasRequired, 'ether');
            if (tokenBalance < value || balance < etherRequired) {
                Promise.reject(new Error(`Not enough founds on ${this.address}, required: [ETH: ${etherRequired}, 2KEY: ${value}], balance: [ETH: ${balance}, 2KEY: ${tokenBalance}]`));
            }
            const params = {from: this.address, gasLimit: this.toHex(this.gas), gasPrice};
            // return this.twoKeyAdmin.transfer2KeyTokensTx(this.twoKeyEconomy.address, to, value).send(params);
            return promisify(this.twoKeyEconomy.transfer, [to, this.toWei(value, 'ether'), params]);
        } catch (err) {
            Promise.reject(err);
        }
    }

    public async transferEther(to: string, value: number, gasPrice: number = this.gasPrice): Promise<any> {
        try {
            const balance = await this._getEthBalance(this.address);
            const gasRequired = await this.getETHTransferGas(to, value);
            const totalValue = value + this.fromWei(gasPrice * gasRequired, 'ether');
            if (totalValue > balance) {
                Promise.reject(new Error(`Not enough founds on ${this.address} required ${value}, balance: ${balance}`));
            }
            const params = {
                to,
                gasPrice,
                gasLimit: this.toHex(this.gas),
                value: this.toWei(value, 'ether').toString(),
                from: this.address
            };
            return new Promise((resolve, reject) => {
                this.web3.eth.sendTransaction(params, async (err, res) => {
                    if (err) {
                        reject(err);
                    } else {
                        resolve(res);
                    }
                });
            });
        } catch (err) {
            Promise.reject(err);
        }
    }

    /* ACQUISITION CAMPAIGN */

    public estimateAcquisitionCampaign(data: AcquisitionCampaign): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const { public_address } = generatePublicMeta();
                const { public_address: public_address2 } = generatePublicMeta();
                const predeployGas = await this._estimateSubcontractGas(contractsMeta.TwoKeyAcquisitionCampaignERC20Predeploy);
                const campaignGas = await this._estimateSubcontractGas(contractsMeta.TwoKeyAcquisitionCampaignERC20, [
                    this._getContractDeployedAddress('TwoKeyEventSource'),
                    this.twoKeyEconomy.address,
                    // Fake WhiteListInfluence address
                    `0x${public_address}`,
                    // Fake WhiteListConverter address
                    `0x${public_address2}`,
                    data.moderator || this.address,
                    data.assetContractERC20,
                    data.campaignStartTime / 1000,
                    data.campaignEndTime / 1000,
                    data.expiryConversion,
                    this.toWei(data.moderatorFeePercentage, 'ether'),
                    this.toWei(data.maxReferralRewardPercent, 'ether'),
                    this.toWei(data.maxConverterBonusPercent, 'ether'),
                    this.toWei(data.pricePerUnitInETH, 'ether'),
                    this.toWei(data.minContributionETH, 'ether'),
                    this.toWei(data.maxContributionETH, 'ether'),
                    data.conversionQuota || 5,
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
                const gasRequired = await this.estimateAcquisitionCampaign(data);
                await this._checkBalanceBeforeTransaction(gasRequired, gasPrice || this.gasPrice);
                let txHash = await this._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20Predeploy, gasPrice, null, progressCallback);
                const predeployReceipt = await this.getTransactionReceiptMined(txHash);
                let contractAddress = Array.isArray(predeployReceipt) ? predeployReceipt[0].contractAddress : predeployReceipt.contractAddress;
                if (progressCallback) {
                    progressCallback('TwoKeyAcquisitionCampaignERC20Predeploy', true, contractAddress);
                }
                const predeployInstance = await this._createAndValidate('TwoKeyAcquisitionCampaignERC20Predeploy', contractAddress);
                // const predeployInstance = await this._createAndValidate('TwoKeyAcquisitionCampaignERC20Predeploy', predeployAddress);
                const [converterWhitelistAddress, referrerWhitelistAddress] = await promisify(predeployInstance.getAddresses, []);
                txHash = await this._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20, gasPrice, [
                    this._getContractDeployedAddress('TwoKeyEventSource'),
                    this.twoKeyEconomy.address,
                    converterWhitelistAddress,
                    referrerWhitelistAddress,
                    data.moderator || this.address,
                    data.assetContractERC20,
                    data.campaignStartTime / 1000,
                    data.campaignEndTime / 1000,
                    data.expiryConversion,
                    this.toWei(data.moderatorFeePercentage, 'ether'),
                    this.toWei(data.maxReferralRewardPercent, 'ether'),
                    this.toWei(data.maxConverterBonusPercent, 'ether'),
                    this.toWei(data.pricePerUnitInETH, 'ether'),
                    this.toWei(data.minContributionETH, 'ether'),
                    this.toWei(data.maxContributionETH, 'ether'),
                    data.conversionQuota || 5,
                ], progressCallback);
                const campaignReceipt = await this.getTransactionReceiptMined(txHash);
                contractAddress = Array.isArray(campaignReceipt) ? campaignReceipt[0].contractAddress : campaignReceipt.contractAddress
                if (progressCallback) {
                    progressCallback('TwoKeyAcquisitionCampaignERC20', true, contractAddress);
                }
                resolve(contractAddress);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Inventory
    public async checkAndUpdateAcquisitionInventoryBalance(campaign: any): Promise<number> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const hash = await promisify(campaignInstance.getAndUpdateInventoryBalance, [{ from: this.address }]);
            await this.getTransactionReceiptMined(hash);
            const balance = this.fromWei(await promisify(campaignInstance.getInventoryBalance, []));
            return Promise.resolve(balance);
        } catch (err) {
            Promise.reject(err);
        }
    }

    // Get Public Link
    public async getAcquisitionPublicLinkKey(campaign: any): Promise<string> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const publicLink = await promisify(campaignInstance.getPublicLinkKey, []);
            return Promise.resolve(publicLink);

        } catch (e) {
            Promise.reject(e)
        }
    }

    public async getAcquisitionReferrerCut(campaign: any): Promise<number> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const cut = (await promisify(campaignInstance.getReferrerCut, [])).toNumber();
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
                // const [decimals, assetSymbol] = await promisify(campaignInstance.getAssetDecimals, []);
                // console.log('Campaign Asset Info', decimals.toNumber(), assetSymbol);
                resolve(publicKey);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Join Offchain
    public joinAcquisitionCampaign(campaign: any, cut: number, referralLink?: string, gasPrice: number = this.gasPrice): Promise<string> {
        // TODO: AP to get current referral Reward:
        // call campaignContracts.contractor => owner
        // cut first address from p_message slice(0,40)
        // compare first_address with owner if !equal call campaignContracts.getCuts => cuts
        // do some magic with cuts https://github.com/2key/web3-alpha/blob/develop/app/javascripts/app.js#L1240
        // result of magic will be maximum possible reward for me
        // then i can join with percent of this reward
        const {public_address, private_key} = generatePublicMeta();
        return new Promise(async (resolve, reject) => {
            try {
                let new_message;
                if (referralLink) {
                    const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
                    console.log('New link for', this.address, f_address, f_secret, p_message);
                    new_message = Sign.free_join(this.address, public_address, f_address, f_secret, p_message, cut);
                } else {
                    await this.setAcquisitionPublicLinkKey(campaign, `0x${public_address}`, gasPrice);
                }
                const raw = `f_address=${this.address}&f_secret=${private_key}&p_message=${new_message || ''}`;
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
                let arcBalance = this.fromWei(await promisify(campaignInstance.balanceOf, [this.address]));
                const {public_address, private_key} = generatePublicMeta();
                const publicLink = `0x${public_address}`;
                if (!arcBalance) {
                    console.log('No Arcs', arcBalance);
                    const msg = Sign.free_take(this.address, f_address, f_secret, p_message);
                    const gas = await promisify(campaignInstance.joinAndSetPublicLinkWithCut.estimateGas, [msg, publicLink, cut, { from: this.address }]);
                    console.log('Gas required for setPubLinkWithCut', gas);
                    const enough = await this._checkBalanceBeforeTransaction(gas, gasPrice);
                    console.log(enough);
                    const txHash = await promisify(campaignInstance.joinAndSetPublicLinkWithCut, [msg, publicLink, cut, { from: this.address, gasPrice, gas }]);
                    console.log('setPubLinkWithCut', txHash);
                    await this.getTransactionReceiptMined(txHash);
                    arcBalance = this.fromWei(await promisify(campaignInstance.balanceOf, [this.address]));
                }
                if (arcBalance) {
                    resolve(`f_address=${this.address}&f_secret=${private_key}&p_message=`)
                } else {
                    reject(new Error('Link is broken!'));
                }
            } catch (err) {
                reject(err);
            }

            // TODO AP Implement method shortUrl
            // If we want to shortLink
            // 1. Check ures tokenArcs TwoKeyAcquisitionCampaignERC20.balanceOf()
            // 2. Transfer Arc if needed TwoKeyAcquisitionCampaignERC20.transferSig(sign.fre_take(...fromHash))
            // 3. Generate new PublicLink (without Hash)
            // 4. TwoKeyAcquisitionCampaignERC20.setPublicLink()
            // 5. If need TwoKeyAcquisitionCampaignERC20.setCut()
        });
    }


    public joinAcquisitionCampaignAndShareARC(campaignAddress: string, referralLink: string, recipient: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
                if (!f_address || !f_secret) {
                    reject('Broken Link');
                }
                const msg = Sign.free_take(this.address, f_address, f_secret, p_message);
                const campaignInstance = await this._getAcquisitionCampaignInstance(campaignAddress);
                const gas = await promisify(campaignInstance.joinAndShareARC.estimateGas, [msg, recipient, { from: this.address }]);
                await this._checkBalanceBeforeTransaction(gas, gasPrice);
                const txHash = await promisify(campaignInstance.joinAndShareARC, [msg, recipient, { from: this.address, gas, gasPrice }]);
                resolve(txHash);
            } catch (e) {
                reject(e);
            }
        });
    }

    /* PARTICIPATE */
    public joinAcquisitionCampaignAndConvert(campaign: any, amount: number, referralLink: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
            if (!f_address || !f_secret) {
                reject('Broken Link');
            }
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const [assetSymbol, decimals] = await promisify(campaignInstance.getContractAttributes, []);
            console.log('Campaign Asset Info', decimals.toNumber(), assetSymbol);
            const [basicTokens, bonusTokens, unit_decimals] = await promisify(campaignInstance.getEstimatedTokenAmount, [this.toWei(amount, 'ether')]);
            // console.log(basicTokens.toNumber(), bonusTokens.toNumber(), unit_decimals);
            console.log('Tokens', this.fromWei(basicTokens).toString(), this.fromWei(bonusTokens).toString());

            const balance = (await promisify(campaignInstance.balanceOf, [this.address])).toNumber();
            if (!balance) {
                console.log('No ARCS call buySign');
                const msg = Sign.free_take(this.address, f_address, f_secret, p_message);
                const gas = await promisify(campaignInstance.joinAndConvert.estimateGas, [msg, { from: this.address, value: this.toWei(amount, 'ether') }]);
                console.log('Gas required for buySign', gas);
                await this._checkBalanceBeforeTransaction(gas, gasPrice);
                const txHash = await promisify(campaignInstance.joinAndConvert, [msg, {from: this.address, gasPrice, gas, value: this.toWei(amount, 'ether')}]);
                await this.getTransactionReceiptMined(txHash);
                resolve(txHash);
            } else {
                console.log('Converter ARCS', balance);
                // const gas = await this._estimateTransactionGas({
                //     from: this.address,
                //     value: this.toWei(amount, 'ether'),
                //     data: campaignInstance.buyProduct.getData(),
                //     to: campaignInstance.address,
                // });
                const gas = await promisify(campaignInstance.convert.estimateGas, [{ from: this.address, value: this.toWei(amount, 'ether') }]);
                console.log('Gas required for buyProduct', gas);
                await this._checkBalanceBeforeTransaction(gas, gasPrice);
                const txHash = await promisify(campaignInstance.convert, [{from: this.address, gasPrice, gas: 7000000, value: this.toWei(amount, 'ether')}]);
                await this.getTransactionReceiptMined(txHash);
                const conversions = await this.getAquisitionConverterConversion(campaignInstance);
                const conversion: any = {};
                Object.keys(conversions).forEach((key) => {
                    if (typeof (conversions[key]) === 'object') {
                        conversion[key] = this.fromWei(conversions[key]);
                    } else {
                        conversion[key] = conversions[key];
                    }
                });
                console.log(conversion);
                resolve(txHash);
            }
        });
    }

    public getAquisitionConverterConversion(campaign: any, address: string = this.address): Promise<any> {
        return new Promise<any>(async (resolve, reject) => {
            try {
                const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
                const conversion = await promisify(campaignInstance.conversions, [address]);
                resolve(conversion);
            } catch (e) {
                reject(e);
            }
        })
    }

    /* UTILS */

    public fromWei(number: string | number | BigNumber, unit?: string): number {
        const result = this.web3.fromWei(number, unit);
        if (result instanceof BigNumber) {
            return result.toNumber();
        }
        return parseFloat(result);
    }

    public toWei(number: string | number | BigNumber, unit?: string): BigNumber {
        return this.web3.toWei(number, unit);
    }

    public toHex(data: any): string {
        return this.web3.toHex(data);
    }

    private _getContractDeployedAddress(contract: string): string {
        return this.contracts ? this.contracts[contract] : contractsMeta[contract].networks[this.networks.mainNetId].address
    }

    private _getGasPrice(): Promise<number> {
        return new Promise((resolve, reject) => {
            this.web3.eth.getGasPrice((err, res) => {
                if (err) {
                    reject(err);
                } else {
                    this.gasPrice = res.toNumber();
                    resolve(this.gasPrice);
                }
            });
        });
    }

    private _getEthBalance(address: string): Promise<number> {
        return new Promise((resolve, reject) => {
            this.web3.eth.getBalance(address, this.web3.eth.defaultBlock, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(this.fromWei(res.toString(), 'ether'));
                }
            })
        })
    }

    private _getTokenBalance(address: string, erc20address?: string): Promise<number> {
        if (erc20address) {
            return new Promise(async (resolve, reject) => {
                try {
                    const erc20 = await this._createAndValidate('ERC20', erc20address);
                    const balance = this.fromWei(await promisify(erc20.balanceOf, [address]));

                    resolve(balance);
                } catch (e) {
                    reject(e);
                }
            });
        }
        return new Promise((resolve, reject) => {
            this.twoKeyEconomy.balanceOf(address, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(this.fromWei(res))
                }
            });
        });
    }

    private _getTotalSupply(erc20address?: string): Promise<number> {
        if (erc20address) {
            return new Promise(async (resolve, reject) => {
                try {
                    const erc20 = await this._createAndValidate('ERC20', erc20address);
                    const balance = this.fromWei(await promisify(erc20.totalSupply, []));
                    resolve(balance);
                } catch (e) {
                    reject(e);
                }
            });
        }
        if (this.totalSupply) {
            return Promise.resolve(this.totalSupply);
        }
        return new Promise((resolve, reject) => {
            this.twoKeyEconomy.totalSupply((err, res) => {
               if (err) {
                   reject(err);
               } else {
                   this.totalSupply = this.fromWei(res);
                   resolve(this.totalSupply);
               }
            });
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
        const balance = await this._getEthBalance(this.address);
        const transactionFee = this.fromWei((gasPrice || this.gasPrice) * gasRequired, 'ether');
        console.log(`${this.address}, ${balance} (${transactionFee}), gasPrice: ${(gasPrice || this.gasPrice)}`);
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

}
