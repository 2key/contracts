import ipfsAPI from 'ipfs-api';
import {BigNumber} from 'bignumber.js';
import solidityContracts from './contracts/meta';
import {ERC20} from './contracts/ERC20';
import {TwoKeyEconomy} from './contracts/TwoKeyEconomy';
import {TwoKeyAdmin} from './contracts/TwoKeyAdmin';
import {TwoKeyEventSource} from './contracts/TwoKeyEventSource';
import {TwoKeyReg} from './contracts/TwoKeyReg';
import {TwoKeyAcquisitionCampaignERC20} from './contracts/TwoKeyAcquisitionCampaignERC20';
import {TwoKeyAcquisitionCampaignERC20Predeploy} from './contracts/TwoKeyAcquisitionCampaignERC20Predeploy';
import {
    EhtereumNetworks,
    ContractsAdressess,
    TwoKeyInit,
    BalanceMeta,
    Transaction,
    CreateCampaign,
    Contract,
    RawTransaction,
} from './interfaces';
import Sign from './sign';
import sign from "./sign";
// import HDWalletProvider from './HDWalletProvider';

const contracts = require('./contracts.json');
// console.log(Sign);
// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
    ipfsIp: '192.168.47.99',
    ipfsPort: '5001',
    mainNetId: 4,
    syncTwoKeyNetId: 17,
};

export default class TwoKeyNetwork {
    private web3: any;
    private syncWeb3: any;
    private ipfs: any;
    private address: string;
    private gasPrice: number;
    private totalSupply: BigNumber;
    private gas: number;
    private networks: EhtereumNetworks;
    private contracts: ContractsAdressess;
    private twoKeyEconomy: TwoKeyEconomy;
    private twoKeyReg: TwoKeyReg;
    private twoKeyAdmin: TwoKeyAdmin;

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
            throw new Error('Web3 instanse required!');
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
        // this.pk = wallet.getPrivateKey().toString('hex');

        this.twoKeyEconomy = new TwoKeyEconomy(this.web3, this._getContractDeployedAddress('TwoKeyEconomy'));
        this.twoKeyReg = new TwoKeyReg(this.web3, this._getContractDeployedAddress('TwoKeyReg'));
        this.twoKeyAdmin = new TwoKeyAdmin(this.web3, this._getContractDeployedAddress('TwoKeyAdmin'));
        // this.twoKeyEventSource = new

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

    public getTotalSupply(): BigNumber {
        return this.totalSupply;
    }

    public getGas(): number {
        return this.gas;
    }

    public getAddress(): string {
        return this.address;
    }

    public getBalance(address: string = this.address): Promise<BalanceMeta> {
        const promises = [
            this._getEthBalance(address),
            this._getTokenBalance(address),
            this._getTotalSupply(),
            this._getGasPrice()
        ];
        return new Promise((resolve, reject) => {
            Promise.all(promises)
                .then(([eth, token, total, gasPrice]) => {
                    resolve({
                        balance: {
                            ETH: parseFloat(eth),
                            total: parseFloat(this.fromWei(total.toString())),
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
            this.twoKeyAdmin.transfer2KeyTokensTx(this.twoKeyEconomy.address, to, value).estimateGas({from: this.address})
                .then(res => {
                    this.gas = res;
                    resolve(this.gas);
                })
                .catch(reject);
        });
    }

    public getETHTransferGas(to: string, value: number): Promise<number> {
        this.gas = null;
        return new Promise((resolve, reject) => {
            this.web3.eth.estimateGas({to, value: this.toWei(value, 'ether').toString()}, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    this.gas = res;
                    resolve(this.gas);
                }
            });
        });
    }

    public async transferTokens(to: string, value: number, gasPrice: number = this.gasPrice): Promise<string> {
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
            return this.twoKeyEconomy.transferTx(to, value).send(params);
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
                Promise.reject(new Error(`Not enough founds on ${this.address} reuired ${value}, balance: ${balance}`));
            }
            const params = {
                to,
                gasPrice,
                gasLimit: this.toHex(this.gas),
                value: this.toWei(value, 'ether').toString(),
                from: this.address
            }
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

    /* HANDLE */

    public setHandle(handle: string, gasPrice: number = this.gasPrice): Promise<string> {
        return this.twoKeyReg.addNameTx(handle, this.address).send({from: this.address, gasPrice, gas: 2000000});
    }

    public getAddressHandle(address: string = this.address): Promise<string> {
        // return this.twoKeyReg.getOwner2Name(address);
        return this.twoKeyReg.getName2Owner(address);
    }

    public async getContractorCampaigns(): Promise<any> {
        const eventSource = await TwoKeyEventSource.createAndValidate(this.web3, this._getContractDeployedAddress('TwoKeyEventSource'));
        // return eventSource.CreatedEvent({ _owner: this.address }).get({ fromBlock: 0, toBlock: 'pending' });
        return eventSource.CreatedEvent({}).get({fromBlock: 0, toBlock: 'pending'});
    }

    /* CAMPAIGN */

    public estimateSaleCampaign(data: CreateCampaign): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const predeployGas = await this._estimateSubcontractGas(solidityContracts.TwoKeyAcquisitionCampaignERC20Predeploy);
                const campaignGas = await this._estimateSubcontractGas(solidityContracts.TwoKeyAcquisitionCampaignERC20, [
                    this._getContractDeployedAddress('TwoKeyEventSource'),
                    this.twoKeyEconomy.address,
                    // Fake WhiteListInfluence address
                    this.twoKeyEconomy.address,
                    // Fake WhiteListConverter address
                    this.twoKeyEconomy.address,
                    data.moderator || this.address,
                    data.openingTime,
                    data.closingTime,
                    data.expiryConversion,
                    data.bonusOffer,
                    data.rate,
                    data.maxCPA,
                    data.erc20address,
                ]);
                // console.log('TwoKeyAcquisitionCampaignERC20', campaignGas);
                const totalGas = predeployGas * 2 + campaignGas;
                resolve(totalGas);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Create Campaign
    public createSaleCampaign(data: CreateCampaign, gasPrice?: number): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const gasRequired = await this.estimateSaleCampaign(data);
                await this._checkBalanceBeforeTransaction(gasRequired, gasPrice || this.gasPrice);
                const predeployAddress = await this._createContract(solidityContracts.TwoKeyAcquisitionCampaignERC20Predeploy, gasPrice);
                const predeployInstance = await TwoKeyAcquisitionCampaignERC20Predeploy.createAndValidate(this.web3, predeployAddress);
                const [whitelistInfluencerAddress, whitelistConverterAddress] = await predeployInstance.getAddresses();
                const campaignAddress = await this._createContract(solidityContracts.TwoKeyAcquisitionCampaignERC20, gasPrice, [
                    this._getContractDeployedAddress('TwoKeyEventSource'),
                    this.twoKeyEconomy.address,
                    whitelistInfluencerAddress,
                    whitelistConverterAddress,
                    data.moderator || this.address,
                    data.openingTime,
                    data.closingTime,
                    data.expiryConversion,
                    data.bonusOffer,
                    data.rate,
                    data.maxCPA,
                    data.erc20address,
                ]);
                const campaign = await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaignAddress);
                // await this._addCampaignInventoryERC20(campaign, data.erc20address, gasPrice);
                resolve(campaign.address);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Inventory
    public addFungibleInventory(campaignAddress: string, amount: number, erc20address: string, gasPrice: number = this.gasPrice): Promise<any> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaign = await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaignAddress);
                const campaignAssetERC20 = await this._getCampaignInventoryERC20(campaign);
                // if (!parseInt(campaignAssetERC20, 16)) {
                //   await this._addCampaignInventoryERC20(campaign, erc20address, gasPrice);
                // }
                const erc20 = await ERC20.createAndValidate(this.web3, erc20address);
                let txHash = await erc20.approveTx(campaign.address, amount).send({from: this.address});
                await this._waitForTransactionMined(txHash);
                // console.log('ERC20 linked');
                // const gas = await campaign.addFungibleAssetTx(amount).estimateGas({ from: this.address });
                // console.log(gas);
                // await this._checkBalanceBeforeTransaction(gas, gasPrice);
                txHash = await campaign.addFungibleAssetTx(amount).send({from: this.address, gas: 70000, gasPrice});
                await this._waitForTransactionMined(txHash);
                const balance = await campaign.checkAndUpdateInventoryBalanceTx().send({from: this.address});
                const balance2 = await erc20.balanceOf(campaign.address);
                resolve(balance);
            } catch (err) {
                reject(err);
            }
        });
    }

    public async getFungibleInventory(campaign: string | TwoKeyAcquisitionCampaignERC20): Promise<number> {
        try {
            const campaignInstance = campaign instanceof TwoKeyAcquisitionCampaignERC20 ? campaign : await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaign);
            // const checkAdnUpdate = new Promise<string>((cResolve, cReject) => {
            //   campaignInstance.checkAndUpdateInventoryBalanceTx().send({ from: this.address }).then((res) => {
            //       console.log(res);
            //       // cResolve(res);
            //     }).catch((cReject));
            // });
            const hash = await campaignInstance.checkAndUpdateInventoryBalanceTx().send({from: this.address});
            console.log('checkAndUpdateInventoryBalance', hash);
            await this._waitForTransactionMined(hash);
            const balance = await campaignInstance.checkInventoryBalance;
            console.log('getFungibleInventory', balance, balance.toString());
            return Promise.resolve(balance.toNumber());
        } catch (err) {
            Promise.reject(err);
        }
    }

    // Set Public Link ()
    public setPublicLink(campaign: string | TwoKeyAcquisitionCampaignERC20, publicKey: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = campaign instanceof TwoKeyAcquisitionCampaignERC20
                    ? campaign
                    : await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaign);
                const gas = await  campaignInstance.setPublicLinkKeyTx(publicKey).estimateGas({ from: this.address });
                await this._checkBalanceBeforeTransaction(gas, this.gasPrice);
                const txHash = await campaignInstance.setPublicLinkKeyTx(publicKey).send({
                    from: this.address,
                    gas,
                    gasPrice
                });
                await this._waitForTransactionMined(txHash);
                const savedPublicKey = await campaignInstance.public_link_key(this.address);
                console.log(`Public Link for (${this.address}) is ${publicKey}`);
                if (savedPublicKey !== publicKey) {
                    console.log('Publick Keys');
                    console.log(savedPublicKey);
                    console.log(publicKey);
                }
                resolve(publicKey);
            } catch (err) {
                reject(err);
            }
        });
    }

    // Join Ofchain
    public joinCampaign(campaign: string | TwoKeyAcquisitionCampaignERC20, cut: number, referralLink?: string, gasPrice: number = this.gasPrice): Promise<string> {
        let pk = Sign.generatePrivateKey();
        let public_address = Sign.privateToPublic(pk);
        const private_key = pk.toString('hex');

        return new Promise(async (resolve, reject) => {
            try {
                let new_message;
                if (referralLink) {
                    const {f_address, f_secret, p_message} = this._getUrlParams(referralLink);
                    new_message = Sign.free_join(this.address, public_address, f_address, f_secret, p_message, cut);
                } else {
                    await this.setPublicLink(campaign, `0x${public_address}`, gasPrice);
                }
                resolve(`f_address=${this.address}&f_secret=${private_key}&p_message=${new_message || ''}`);
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
                const campaignInstance = await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaignAddress);
                const arcBalance = (await campaignInstance.balanceOf(this.address)).toNumber();
                if (!arcBalance) {
                    console.log('No Arcs');
                    const msg = Sign.free_take(this.address, f_address, f_secret, p_message);
                    console.log('MSG', msg);
                    // const gas = await campaignInstance.transferSigTx([msg]).estimateGas({ from: this.address });
                    // await this._checkBalanceBeforeTransaction(gas, gasPrice);
                    // campaignInstance.FulfilledEvent({}).watch({}, (err, event) => {
                    //     console.log('FulfilledEvent', err, event);
                    // });
                    const txHash = await campaignInstance.transferSigTx([msg]).send({ from: this.address, gasPrice, gas: 7000000 });
                    // console.log('transferSigTx', txHash);
                    await this._waitForTransactionMined(txHash);
                    // const q = new Promise((resolve) => {
                    //     setTimeout(() => {
                    //         resolve();
                    //     }, 30000);
                    // });
                    // await q;
                }
                resolve(this.joinCampaign(campaignInstance, cut || 0, null, gasPrice));
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

    public getInfluencerReward(campaign: string | TwoKeyAcquisitionCampaignERC20, influencerAddress: string = this.address): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = campaign instanceof TwoKeyAcquisitionCampaignERC20 ? campaign : await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaign);
                const balance = await campaignInstance.influencer2cut(influencerAddress);
                resolve(balance.toNumber());
            } catch (err) {
                reject(err);
            }
        });
    }

    /* PARTICIPATE */
    // public buyCampaignAssetsWithETH(campaignAddress: string, amount: number, referralLink: string, gasPrice: number = this.gasPrice): Promise<string> {
    //   return new Promise(async (resolve, reject) => {
    //     const { f_address, f_secret, p_message } = this._getUrlParams(referralLink);
    //     if (!f_address || !f_secret) {
    //       reject('Broken Link');
    //     }
    //     const campaign = await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaignAddress);
    //     campaign.balanceOf(this.address);
    //     const msg = Sign.free_take(this.address, f_address, f_secret, p_message);
    //
    //     resolve(msg);
    //   });
    // }

    /* UTILS */

    public fromWei(number: string | number | BigNumber, unit?: string): string {
        return this.web3.fromWei(number, unit);
    }

    public toWei(number: string | number | BigNumber, unit?: string): number | BigNumber {
        return this.web3.toWei(number, unit);
    }

    public toHex(data: any): string {
        return this.web3.toHex(data);
    }

    private _getContractDeployedAddress(contract: string): string {
        return this.contracts ? this.contracts[contract] : solidityContracts[contract].networks[this.networks.mainNetId].address
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

    private _getTokenBalance(address: string): Promise<string> {
        return new Promise((resolve, reject) => {
            this.twoKeyEconomy.balanceOf(address)
                .then(res => {
                    resolve(res.toString())
                })
                .catch(reject);
        });
    }

    private _getTotalSupply(): Promise<string> {
        if (this.totalSupply) {
            return Promise.resolve(this.totalSupply.toString());
        }
        return new Promise((resolve, reject) => {
            this.twoKeyEconomy.totalSupply
                .then(res => {
                    this.totalSupply = res;
                    resolve(this.totalSupply.toString());
                })
                .catch(reject);
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

    private _createContract(contract: Contract, gasPrice: number = this.gasPrice, params?: any[]): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {abi, bytecode: data} = contract;
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
                        resolve(res.address);
                    } // else {
                    // console.log('Transaction Hash:', res.transactionHash);
                    // }
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

    private _getNonce(): Promise<number> {
        return new Promise((resolve, reject) => {
            this.web3.eth.getTransactionCount(this.address, 'pending', (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    // console.log('NONCE', res, this.address);
                    resolve(res);
                }
            });
        });
    }

    private _getBlock(block: string | number): Promise<Transaction> {
        return new Promise((resolve, reject) => {
            this.web3.eth.getBlock(block, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(res);
                }
            });
        });
    }

    private _waitForTransactionMined(txHash: string, timeout: number = 60000): Promise<boolean> {
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
                    resolve(true);
                }
            }, 1000);
        });
    }

    private _ipfsAdd(data: any): Promise<string> {
        return new Promise((resolve, reject) => {
            this.ipfs.add([Buffer.from(JSON.stringify(data))], (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(res[0].hash);
                }
            });
        })
    }

    private _getUrlParams(url: string): any {
        let hashes = url.slice(url.indexOf('?') + 1).split('&');
        let params = {};
        hashes.map(hash => {
            let [key, val] = hash.split('=')
            params[key] = decodeURIComponent(val);
        })
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

    // Add Asset ERC20 Contract
    // private _addCampaignInventoryERC20(campaign: string | TwoKeyAcquisitionCampaignERC20, erc20: string, gasPrice: number = this.gasPrice): Promise<string> {
    //   return new Promise(async (resolve, reject) => {
    //     try {
    //       const campaignInstance = campaign instanceof TwoKeyAcquisitionCampaignERC20 ? campaign : await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaign);
    //       const data = {
    //         from: this.address,
    //         to: campaignInstance.address,
    //         value: '0x0',
    //         data: campaignInstance.addAssetContractERC20Tx(erc20).getData()
    //       }
    //       const gas = await this._estimateTransactionGas(data);
    //       await this._checkBalanceBeforeTransaction(gas, gasPrice);
    //       const txHash = await campaignInstance.addAssetContractERC20Tx(erc20).send({ from: this.address, gasPrice, gas });
    //       await this._waitForTransactionMined(txHash)
    //       resolve(erc20);
    //     } catch (err) {
    //       reject(err);
    //     }
    //
    //   });
    // }
    // Get Asset ERC20 Contract
    private _getCampaignInventoryERC20(campaign: string | TwoKeyAcquisitionCampaignERC20): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = campaign instanceof TwoKeyAcquisitionCampaignERC20 ? campaign : await TwoKeyAcquisitionCampaignERC20.createAndValidate(this.web3, campaign);
                const currentErc20address = await campaignInstance.getAssetContractAddress;
                resolve(currentErc20address);
            } catch (err) {
                reject(err);
            }
        });
    }
}
