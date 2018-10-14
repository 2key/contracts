import {BigNumber} from 'bignumber.js';
import contractsMeta from '../contracts';
import {promisify} from './index';
import {IContract, ICreateCampaignProgress, IRawTransaction, ITransaction, ITwoKeyBase,} from '../interfaces';

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

export default class Helpers {
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
                const totalSupply = await promisify(erc20.totalSupply, [{ from: this.base.address }]);
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

    _createContract(contract: IContract, gasPrice: number = this.gasPrice, params?: any[], progressCallback?: ICreateCampaignProgress): Promise<string> {
        return new Promise(async (resolve, reject) => {
            const {abi, bytecode: data, name} = contract;
            const createParams = params ? [...params] : [];
            createParams.push({data, from: this.base.address, gasPrice});
            this.base._log('CREATE CONTRACT', name, params, this.base.address, gasPrice);
            let resolved: boolean = false;
            this.base.web3.eth.contract(abi).new(...createParams, (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    if (!resolved) {
                        // if (res.address) {
                        //     resolve(res.address);
                        // }
                        if (progressCallback) {
                            progressCallback(name, false, res.transactionHash);
                        }
                        resolved = true;
                        resolve(res.transactionHash);
                    }
                }
            });
        });
    }

    _estimateSubcontractGas(contract: IContract, params?: any[]): Promise<number> {
        return new Promise(async (resolve, reject) => {
            const {abi, bytecode: data} = contract;
            const estimateParams = params ? [...params, {data, from: this.base.address}] : [{data, from: this.base.address}];
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

    // _getNonce(): Promise<number> {
    //     return new Promise((resolve, reject) => {
    //         this.base.web3.eth.getTransactionCount(this.base.address, 'pending', (err, res) => {
    //             if (err) {
    //                 reject(err);
    //             } else {
    //                 // console.log('NONCE', res, this.base.address);
    //                 resolve(res);
    //             }
    //         });
    //     });
    // }

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

    async _checkBalanceBeforeTransaction(gasRequired: number, gasPrice: number): Promise<boolean> {
        if (!this.gasPrice) {
            await this._getGasPrice();
        }
        const balance = this.base.web3.fromWei(await this._getEthBalance(this.base.address), 'ether');
        const transactionFee = this.base.web3.fromWei((gasPrice || this.gasPrice) * gasRequired, 'ether');
        this.base._log(`_checkBalanceBeforeTransaction ${this.base.address}, ${balance} (${transactionFee}), gasPrice: ${(gasPrice || this.gasPrice)}`);
        if (transactionFee > balance) {
            throw new Error(`Not enough founds. Required: ${transactionFee}. Your balance: ${balance},`);
        }
        return true;
    }

    async _getAcquisitionCampaignInstance(campaign: any): Promise<any> {
        return campaign.address
            ? campaign
            : await this._createAndValidate('TwoKeyAcquisitionCampaignERC20', campaign);
    }

    async _getERC20Instance(erc20: any): Promise<any> {
        return erc20.address
            ? erc20
            : await this._createAndValidate('ERC20full', erc20);
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
