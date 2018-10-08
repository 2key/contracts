import {BigNumber} from 'bignumber.js';
import LZString from 'lz-string';
import {
    BalanceMeta,
    IBalanceNormalized,
    ITransactionReceipt,
    ITwoKeyBase, ITwoKeyHelpers,
} from '../interfaces';

export function promisify(func: any, args: any): Promise<any> {
    return new Promise((res, rej) => {
        func(...args, (err: any, data: any) => {
            if (err) return rej(err);
            return res(data);
        });
    });
}

export default class Utils {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;

    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
    }
    /* UTILS */
    ipfsAdd(data: any): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const dataString = JSON.stringify(data);
                // console.log('Raw length', dataString.length);
                // const compressed = LZString.compressToUint8Array(dataString);
                // const compressed = LZString.compress(dataString);
                // console.log('Compressed length', compressed.length, compressed);
                // console.log('Compressed length', compressed.length);
                const [pinned]= await promisify(this.base.ipfs.add, [[Buffer.from(dataString)], { pin: true }]);
                // const pin = await promisify(this.base.ipfs.pin.add, [hash[0].hash]);
                resolve(pinned.hash);
            } catch (e) {
                reject(e);
            }
        });
    }

    public fromWei(number: number | string | BigNumber, unit?: string): string | BigNumber {
        return this.base.web3.fromWei(number, unit);
    }

    public toWei(number: string | number | BigNumber, unit?: string): BigNumber {
        return this.base.web3.toWei(number, unit);
    }

    public toHex(data: any): string {
        return this.base.web3.toHex(data);
    }

    public getBalanceOfArcs(campaign: any, address: string = this.base.address): Promise<number> {
        return new Promise(async (resolve, reject) => {
            try {
                const campaignInstance = await this.helpers._getAcquisitionCampaignInstance(campaign);
                const balance = (await promisify(campaignInstance.balanceOf, [address])).toNumber();
                resolve(balance);
            } catch (e) {
                reject(e);
            }
        });
    }

    public balanceFromWeiString(meta: BalanceMeta, inWei: boolean = false, toNum: boolean = false): IBalanceNormalized {
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

    getTransactionReceiptMined(txHash: string, web3: any = this.base.web3, interval: number = 500, timeout: number = 60000): Promise<ITransactionReceipt> {
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
