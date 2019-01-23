import {BigNumber} from 'bignumber.js';
import contractsMeta from '../contracts';
import {promisify} from './index';
import {ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {IContract, ICreateContractOpts, IRawTransaction, ITransaction} from './interfaces';

function toBuffer(ab: Uint8Array): Buffer {
    const buffer = new Buffer(ab.byteLength);
    const l = buffer.length;
    for (let i = 0; i < l; i++) {
        buffer[i] = ab[i];
    }
    return buffer
}

function toUint8Array(buffer: Buffer): Uint8Array {
    const ab = new Uint8Array(buffer.length);
    const l = buffer.length;
    for (let i = 0; i < l; i++) {
        ab[i] = buffer[i];
    }
    return ab;
}

export default class Helpers implements ITwoKeyHelpers {
    readonly base: ITwoKeyBase;
    gasPrice: number;

    constructor(base: ITwoKeyBase) {
        this.base = base;
    }

    _normalizeString(value: number | string | BigNumber, inWei: boolean): string {
        return parseFloat(inWei ? this.base.web3.fromWei(value, 'ether').toString() : value.toString()).toString();
    }

    _normalizeNumber(value: number | string | BigNumber, inWei: boolean): number {
        return parseFloat(inWei ? this.base.web3.fromWei(value, 'ether').toString() : value.toString());
    }

    _getContractDeployedAddress(contract: string): string {
        return contractsMeta[contract].networks[this.base.networks.mainNetId].address
    }

    _getGasPrice(): Promise<number | string | BigNumber> {
        return new Promise(async (resolve, reject) => {
            try {
                const gasPrice = await promisify(this.base.web3.eth.getGasPrice, []);
                this.base._setGasPrice(gasPrice.toNumber());
                this.gasPrice = gasPrice.toNumber();
                resolve(gasPrice);
            } catch (e) {
                reject(e);
            }
        });
    }

    _getEthBalance(address: string): Promise<number | string | BigNumber> {
        return new Promise(async (resolve, reject) => {
            try {
                resolve(await promisify(this.base.web3.eth.getBalance, [address, this.base.web3.eth.defaultBlock]));
            } catch (e) {
                reject(e);
            }
        })
    }

    _getTokenBalance(address: string, erc20address: string = this.base.twoKeyEconomy.address): Promise<number | string | BigNumber> {
        return new Promise(async (resolve, reject) => {
            try {
                const erc20 = await this._createAndValidate('ERC20full', erc20address);
                const balance = await promisify(erc20.balanceOf, [address]);

                resolve(balance);
            } catch (e) {
                reject(e);
            }
        });
    }

    _getTotalSupply(erc20address: string = this.base.twoKeyEconomy.address): Promise<number | string | BigNumber> {
        return new Promise(async (resolve, reject) => {
            try {
                const erc20 = await this._createAndValidate('ERC20full', erc20address);
                const totalSupply = await promisify(erc20.totalSupply, []);
                this.base._setTotalSupply(totalSupply);
                resolve(totalSupply);
            } catch (e) {
                reject(e);
            }
        });
    }

    public _getTransaction(txHash: string): Promise<ITransaction> {
        return new Promise((resolve, reject) => {
            this.base.web3.eth.getTransaction(txHash, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(res);
                }
            });
        });
    }

    _createContract(contract: IContract, from: string, {gasPrice = this.gasPrice, params, progressCallback, link}: ICreateContractOpts = {}): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {abi, name} = contract;
            let data = contract.bytecode;
            if (link) {
                console.log('LINK', Object.keys(link));
                let template = `__${link.name}`;
                for (let i = 0; i < 40 - link.name.length - 2; i++) {
                    template += '_';
                }
                data = data.replace(new RegExp(template, 'g'), link.address.substring(2));
            }
            const nonce = await this._getNonce(from);
            const createParams = params ? [...params] : [];
            createParams.push({data, from, gasPrice, nonce});
            this.base._log('CREATE CONTRACT', name, params, from, gasPrice, nonce);
            let resolved: boolean = false;
            this.base.web3.eth.contract(abi).new(...createParams, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    // this.base._log(name, res);
                    if (!resolved) {
                        // if (res.address) {
                        //     resolve(res.address);
                        // }
                        if (progressCallback) {
                            progressCallback(name, false, res.transactionHash);
                        }
                        resolve(res.transactionHash);
                        resolved = true;
                    }
                }
            });
        });
    }

    _estimateSubcontractGas(contract: IContract, from: string, params?: any[]): Promise<number> {
        return new Promise(async (resolve, reject) => {
            const {abi, bytecode: data} = contract;
            const estimateParams = params ? [...params, {data, from}] : [{data, from}];
            this.base.web3.eth.estimateGas({
                data: this.base.web3.eth.contract(abi).new.getData(...estimateParams),
            }, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(res);
                }
            })
        });
    }

    _estimateTransactionGas(data: IRawTransaction): Promise<number> {
        return new Promise((resolve, reject) => {
            this.base.web3.eth.estimateGas(data, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(res);
                }
            });
        });
    }

    _getNonce(from: string): Promise<number> {
        return new Promise((resolve, reject) => {
            this.base.web3.eth.getTransactionCount(from, 'pending', (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    console.log('NONCE', res, from);
                    resolve(res);
                }
            });
        });
    }

    // _getBlock(block: string | number): Promise<ITransaction> {
    //     return new Promise((resolve, reject) => {
    //         this.base.web3.eth.getBlock(block, (err, res) => {
    //             if (err) {
    //                 reject(err);
    //             } else {
    //                 resolve(res);
    //             }
    //         });
    //     });
    // }

    _getUrlParams(url: string): any {
        let hashes = url.slice(url.indexOf('?') + 1).split('&');
        let params = {};
        hashes.map(hash => {
            let [key, val] = hash.split('=');
            params[key] = decodeURIComponent(val);
        });
        return params;
    }

    async _checkBalanceBeforeTransaction(gasRequired: number, gasPrice: number, from: string): Promise<boolean> {
        if (!this.gasPrice) {
            await this._getGasPrice();
        }
        const balance = this.base.web3.fromWei(await this._getEthBalance(from), 'ether');
        const transactionFee = this.base.web3.fromWei((gasPrice || this.gasPrice) * gasRequired, 'ether');
        this.base._log(`_checkBalanceBeforeTransaction ${from}, ${balance} (${transactionFee}), gasPrice: ${(gasPrice || this.gasPrice)}`);
        if (transactionFee > balance) {
            throw new Error(`Not enough founds. Required: ${transactionFee}. Your balance: ${balance},`);
        }
        return true;
    }

    async _getLockupContractInstance(lockupContract: any) : Promise<any> {
        return lockupContract.address
            ? lockupContract
            : await this._createAndValidate('TwoKeyLockupContract', lockupContract);
    }

    async _getAcquisitionCampaignInstance(campaign: any): Promise<any> {
        return campaign.address
            ? campaign
            : await this._createAndValidate('TwoKeyAcquisitionCampaignERC20', campaign);
    }

    async _getAirdropCampaignInstance(campaign: any) : Promise<any> {
        return campaign.address
            ? campaign
            : await this._createAndValidate('TwoKeyAirdropCampaign', campaign);
    }

    async _getWeightedVoteContract(campaign: any): Promise<any> {
        return campaign.address
            ? campaign
            : await this._createAndValidate('TwoKeyWeightedVoteContract', campaign);
    }

    async _getDecentralizedNationInstance(decentralizedNation: any) : Promise<any> {
        return decentralizedNation.address
        ? decentralizedNation
            : await this._createAndValidate('DecentralizedNation', decentralizedNation);
    }

    async _getTwoKeyCongressInstance(congress: any): Promise<any> {
        return congress.address
            ? congress
            : await this._createAndValidate('TwoKeyCongress',congress);
    }

    async _getERC20Instance(erc20: any): Promise<any> {
        return erc20.address
            ? erc20
            : await this._createAndValidate('ERC20full', erc20);
    }

    async _getUpgradableExchangeInstance(upgradableExchange: any) : Promise<any> {
        return upgradableExchange.address
            ? upgradableExchange
            : await this._createAndValidate('TwoKeyUpgradableExchange', upgradableExchange);
    }
    async _getTwoKeyRegInstance(twoKeyReg: any) : Promise<any> {
        return twoKeyReg.address
            ? twoKeyReg
            : await this._createAndValidate('TwoKeyRegLogic', twoKeyReg);
    }

    async _getTwoKeyAdminInstance(twoKeyAdmin: any) : Promise<any> {
        return twoKeyAdmin.address
            ? twoKeyAdmin
            : await this._createAndValidate('TwoKeyAdmin', twoKeyAdmin);
    }

    async _createAndValidate(
        contractName: string,
        address: string
    ): Promise<any> {
        const code = await promisify(this.base.web3.eth.getCode, [address]);
        // in case of missing smartcontract, code can be equal to "0x0" or "0x" depending on exact web3 implementation
        // to cover all these cases we just check against the source code length — there won't be any meaningful EVM program in less then 3 chars
        if (code.length < 4 || !contractsMeta[contractName]) {
            throw new Error(`Contract at ${address} doesn't exist!`);
        }
        return this.base.web3.eth.contract(contractsMeta[contractName].abi).at(address);
    }

    _checkIPFS(): Promise<boolean> {
        return new Promise<boolean>(async (resolve, reject) => {
            try {
                const ipfs = await promisify(this.base.ipfs.id, []);
                resolve(Boolean(ipfs && ipfs.id));
            } catch (e) {
                reject(e);
            }
        });
    }
}
