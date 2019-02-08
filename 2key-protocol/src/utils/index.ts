import {BigNumber} from 'bignumber.js';
import { BalanceMeta, ITwoKeyBase, IOffchainData } from '../interfaces';
import {
    IBalanceFromWeiOpts,
    IBalanceNormalized,
    ITransactionReceipt,
    ITwoKeyHelpers,
    ITwoKeyUtils,
    ITxReceiptOpts,
} from './interfaces';
import { promisify } from './promisify';

const units = {
    3: 'kwei',
    6: 'mwei',
    9: 'gwei',
    12: 'szabo',
    15: 'finney',
    18: 'ether',
    21: 'kether',
    24: 'mether',
    27: 'gether',
    30: 'tether',
}

export default class Utils implements ITwoKeyUtils {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
    }
    /* UTILS */
    public ipfsAdd(data: any): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const dataString = typeof data === 'string' ? data : JSON.stringify(data);
                // console.log('Raw length', dataString.length);
                // const compressed = LZString.compressToUint8Array(dataString);
                // const compressed = LZString.compress(dataString);
                // console.log('Compressed length', compressed.length, compressed);
                // console.log('Compressed length', compressed.length);
                const [pinned]= await promisify(this.base.ipfsW.add, [[Buffer.from(dataString)], { pin: true }]);
                // const pin = await promisify(this.base.ipfs.pin.add, [hash[0].hash]);
                resolve(pinned.hash);
            } catch (e) {
                reject(e);
            }
        });
    }

    public getOffchainDataFromIPFSHash(hash: string): Promise<IOffchainData> {
        return new Promise<IOffchainData>(async (resolve, reject) => {
            try {
                const offchainObj = JSON.parse((await promisify(this.base.ipfsR.cat, [hash])).toString());
                // console.log('GETOFFCHAIN', hash, compressed);
                // const ab = new Uint8Array(compressed);
                // console.log(ab);
                // const raw = LZString.decompress(compressed);
                // const raw = LZString.decompressFromUint8Array(toUint8Array(compressed));
                // const raw = LZString.decompressFromUint8Array(ab);
                // console.log('RAW', raw);
                // const offchainObj = JSON.parse(raw);
                // console.log('OFFCHAIN OBJECT', raw, offchainObj);
                resolve(offchainObj);
            } catch (e) {
                reject(e);
            }
        });
    }

    public transferEther(to: string, value: number | string | BigNumber, from: string): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const nonce = await this.helpers._getNonce(from);
                const params = {to, value, from, nonce};
                const txHash = await promisify(this.base.web3.eth.sendTransaction, [params]);
                resolve(txHash);
            } catch (err) {
                reject(err);
            }
        });
    }

    public fromWei(number: number | string | BigNumber, unit?: string | number): string | BigNumber {
        const web3Unit = unit && typeof unit === 'string' ? unit : units[unit];
        return this.base.web3.fromWei(number, web3Unit);
    }

    public toWei(number: number | string | BigNumber, unit?: string | number): BigNumber {
        const web3Unit = unit && typeof unit === 'string' ? unit : units[unit];
        return this.base.web3.toWei(number, web3Unit);
    }

    public toHex(data: any): string {
        return this.base.web3.toHex(data);
    }

    public balanceFromWeiString(meta: BalanceMeta, { inWei, toNum }: IBalanceFromWeiOpts = {}): IBalanceNormalized {
        return {
            balance: {
                ETH: toNum ? this.helpers._normalizeNumber(meta.balance.ETH, inWei) : this.helpers._normalizeString(meta.balance.ETH, inWei),
                '2KEY': toNum ? this.helpers._normalizeNumber(meta.balance['2KEY'], inWei) : this.helpers._normalizeString(meta.balance['2KEY'], inWei),
                total: toNum ? this.helpers._normalizeNumber(meta.balance.total, inWei) : this.helpers._normalizeString(meta.balance.total, inWei)
            },
            local_address: meta.local_address,
            // gasPrice: toNum ? this._normalizeNumber(meta.gasPrice, inWei) : this._normalizeString(meta.gasPrice, inWei),
            gasPrice: toNum ? this.helpers._normalizeNumber(meta.gasPrice, false) : this.helpers._normalizeString(meta.gasPrice, false),
        }
    }

    public getTransactionReceiptMined(txHash: string, { web3 = this.base.web3, timeout = 60000, interval = 500}: ITxReceiptOpts = {}): Promise<ITransactionReceipt> {
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
}
