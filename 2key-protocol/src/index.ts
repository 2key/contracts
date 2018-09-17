import ipfsAPI from 'ipfs-api';
import {BigNumber} from 'bignumber.js';
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

function promisify(func: any, args: any): Promise<any> {
    return new Promise((res, rej) => {
        func(...args, (err: any, data: any) => {
            if (err) return rej(err);
            return res(data);
        });
    });
}

// const contracts = require('./contracts.json');
// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
    ipfsIp: '192.168.47.99',
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
    private totalSupply: string;
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

    public getTotalSupply(): string {
        return this.totalSupply;
    }

    public getGas(): number {
        return this.gas;
    }

    public getAddress(): string {
        return this.address;
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
                            ETH: parseFloat(eth),
                            total: parseFloat(total),
                            '2KEY': parseFloat(token),
                        },
                        local_address: this.address,
                        gasPrice: parseFloat(gasPrice),
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
            const balance = parseFloat(await this._getEthBalance(this.address));
            const tokenBalance = parseFloat(await this._getTokenBalance(this.address));
            const gasRequired = await this.getERC20TransferGas(to, value);
            const etherRequired = parseFloat(this.fromWei(gasPrice * gasRequired, 'ether'));
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
            const balance = parseFloat(await this._getEthBalance(this.address));
            const gasRequired = await this.getETHTransferGas(to, value);
            const totalValue = value + parseFloat(this.fromWei(gasPrice * gasRequired, 'ether'));
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

    /* CAMPAIGN */

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
                    data.openingTime,
                    data.closingTime,
                    data.expiryConversion,
                    data.bonusOffer,
                    this.toWei(data.rate, 'ether'),
                    data.maxCPA,
                    data.erc20address,
                    data.quota || 5,
                ]);
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
                const predeployReceipt = await this._waitForTransactionMined(txHash);
                if (progressCallback) {
                    progressCallback('TwoKeyAcquisitionCampaignERC20Predeploy', true, predeployReceipt.contractAddress);
                }
                const predeployInstance = await this._createAndValidate('TwoKeyAcquisitionCampaignERC20Predeploy', predeployReceipt.contractAddress);
                // const predeployInstance = await this._createAndValidate('TwoKeyAcquisitionCampaignERC20Predeploy', predeployAddress);
                const [whitelistInfluencerAddress, whitelistConverterAddress] = await promisify(predeployInstance.getAddresses, []);
                txHash = await this._createContract(contractsMeta.TwoKeyAcquisitionCampaignERC20, gasPrice, [
                    this._getContractDeployedAddress('TwoKeyEventSource'),
                    this.twoKeyEconomy.address,
                    whitelistInfluencerAddress,
                    whitelistConverterAddress,
                    data.moderator || this.address,
                    data.openingTime,
                    data.closingTime,
                    data.expiryConversion,
                    data.bonusOffer,
                    this.toWei(data.rate, 'ether'),
                    data.maxCPA,
                    data.erc20address,
                    data.quota || 5,
                ], progressCallback);
                const campaignReceipt = await this._waitForTransactionMined(txHash);
                if (progressCallback) {
                    progressCallback('TwoKeyAcquisitionCampaignERC20', true, campaignReceipt.contractAddress);
                }
                resolve(campaignReceipt.contractAddress);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Inventory
    public async checkAndUpdateFungibleInventory(campaign: any): Promise<number> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const hash = await promisify(campaignInstance.checkAndUpdateInventoryBalance, [{ from: this.address }]);
            await this._waitForTransactionMined(hash);
            const balance = parseFloat(this.fromWei(await promisify(campaignInstance.checkInventoryBalance, [])));
            return Promise.resolve(balance);
        } catch (err) {
            Promise.reject(err);
        }
    }

    // Get Public Link
    public async getPublicLink(campaign: any, address: string = this.address): Promise<string> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const publicLink = await promisify(campaignInstance.public_link_key, [address]);
            return Promise.resolve(publicLink);

        } catch (e) {
            Promise.reject(e)
        }
    }

    public async getReferrerCut(campaign: any, address: string = this.address): Promise<number> {
        try {
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const cut = (await promisify(campaignInstance.influencer2cut, [address])).toNumber();
            return Promise.resolve(cut);
        } catch (e) {
            Promise.reject(e);
        }
    }

    // Set Public Link
    public setPublicLink(campaign: any, publicKey: string, gasPrice: number = this.gasPrice): Promise<string> {
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
                await this._waitForTransactionMined(txHash);
                resolve(publicKey);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Join Ofchain
    public joinCampaign(campaign: any, cut: number, referralLink?: string, gasPrice: number = this.gasPrice): Promise<string> {
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
                    await this.setPublicLink(campaign, `0x${public_address}`, gasPrice);
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
    public shortUrl(campaignAddress: string, referralLink: string, cut?: number, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
            if (!f_address || !f_secret) {
                reject('Broken Link');
            }
            try {

                const campaignInstance = await this._getAcquisitionCampaignInstance(campaignAddress);
                let arcBalance = parseFloat(this.fromWei(await promisify(campaignInstance.balanceOf, [this.address])));
                const {public_address, private_key} = generatePublicMeta();
                const publicLink = `0x${public_address}`;
                if (!arcBalance) {
                    console.log('No Arcs', arcBalance);
                    const msg = Sign.free_take(this.address, f_address, f_secret, p_message);
                    const gas = await promisify(campaignInstance.setPubLinkWithCut.estimateGas, [msg, publicLink, cut, { from: this.address }]);
                    console.log('Gas required for setPubLinkWithCut', gas);
                    await this._checkBalanceBeforeTransaction(gas, gasPrice);
                    const txHash = await promisify(campaignInstance.setPubLinkWithCut, [msg, publicLink, cut, {from: this.address, gasPrice, gas}]);
                    console.log('setPubLinkWithCut', txHash);
                    await this._waitForTransactionMined(txHash);
                    arcBalance = parseFloat(this.fromWei(await promisify(campaignInstance.balanceOf, [this.address])));
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

    /* PARTICIPATE */
    public buyCampaignAssetsWithETH(campaign: any, amount: number, referralLink: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
            if (!f_address || !f_secret) {
                reject('Broken Link');
            }
            const campaignInstance = await this._getAcquisitionCampaignInstance(campaign);
            const balance = (await promisify(campaignInstance.balanceOf, [this.address])).toNumber();
            if (!balance) {
                console.log('No ARCS call buySign');
                const msg = Sign.free_take(this.address, f_address, f_secret, p_message);
                const gas = await promisify(campaignInstance.buySign.estimateGas, [msg, { from: this.address }]);
                console.log('Gas required for buySign', gas);
                await this._checkBalanceBeforeTransaction(gas, gasPrice);
                const txHash = await promisify(campaignInstance.buySign, [msg, {from: this.address, gasPrice, gas, value: this.toWei(amount, 'ether')}]);
                await this._waitForTransactionMined(txHash);
                resolve(txHash);
            } else {
                console.log('Converter ARCS', balance);
                // const gas = await this._estimateTransactionGas({
                //     from: this.address,
                //     value: this.toWei(amount, 'ether'),
                //     data: campaignInstance.buyProduct.getData(),
                //     to: campaignInstance.address,
                // });
                // const gas = await promisify(campaignInstance.buyProduct.estimateGas, [{ from: this.address, value: this.toWei(amount, 'ether') }]);
                // console.log('Gas required for buyProduct', gas);
                // await this._checkBalanceBeforeTransaction(gas, gasPrice);
                const txHash = await promisify(campaignInstance.buyProduct, [{from: this.address, gasPrice, gas: 7000000, value: this.toWei(amount, 'ether')}]);
                await this._waitForTransactionMined(txHash);
                resolve(txHash);
            }
        });
    }

    /* UTILS */

    public fromWei(number: string | number | BigNumber, unit?: string): string {
        return this.web3.fromWei(number, unit);
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

    private _getGasPrice(): Promise<string> {
        return new Promise((resolve, reject) => {
            this.web3.eth.getGasPrice((err, res) => {
                if (err) {
                    reject(err);
                } else {
                    this.gasPrice = res.toNumber();
                    resolve(res.toString());
                }
            });
        });
    }

    private _getEthBalance(address: string): Promise<string> {
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

    private _getTokenBalance(address: string, erc20address?: string): Promise<string> {
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

    private _getTotalSupply(erc20address?: string): Promise<string> {
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
            return Promise.resolve(this.totalSupply.toString());
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

    private _waitForTransactionMined(txHash: string, timeout: number = 60000): Promise<TransactionReceipt> {
        return new Promise((resolve, reject) => {
            let fallbackTimer;
            let interval;
            fallbackTimer = setTimeout(() => {
                if (interval) {
                    clearInterval(interval);
                    interval = null;
                }
                if (fallbackTimer) {
                    clearTimeout(fallbackTimer);
                    fallbackTimer = null;
                }
                reject();
            }, timeout);
            interval = setInterval(async () => {
                let tx = await this._getTransaction(txHash);
                if (tx.blockNumber) {
                    if (fallbackTimer) {
                        clearTimeout(fallbackTimer);
                        fallbackTimer = null;
                    }
                    if (interval) {
                        clearInterval(interval);
                        interval = null;
                    }
                    const txReceipt = await promisify(this.web3.eth.getTransactionReceipt, [txHash]);
                    resolve(txReceipt);
                }
            }, 1000);
        });
    }

    // private _ipfsAdd(data: any): Promise<string> {
    //     return new Promise((resolve, reject) => {
    //         this.ipfs.add([Buffer.from(JSON.stringify(data))], (err, res) => {
    //             if (err) {
    //                 reject(err);
    //             } else {
    //                 resolve(res[0].hash);
    //             }
    //         });
    //     })
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
        const balance = parseFloat(await this._getEthBalance(this.address));
        const transactionFee = parseFloat(this.fromWei(gasPrice || this.gasPrice * gasRequired, 'ether'));

        if (transactionFee > balance) {
            throw new Error(`Not enough founds. Required: ${transactionFee}. Your balance: ${balance}`);
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
