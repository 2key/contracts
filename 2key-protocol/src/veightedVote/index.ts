import {ICreateOpts, ITwoKeyBase, ITwoKeyHelpers} from '../interfaces';
import {ITwoKeyWeightedVoteConstructor, ITwoKeyWeightedVoteContract} from './interfaces';
import contracts from "../contracts";
import {ITwoKeyUtils} from "../utils/interfaces";

export default class TwoKeyWeightedVoteContract implements ITwoKeyWeightedVoteContract {
    private readonly base: ITwoKeyBase;
    private readonly helpers: ITwoKeyHelpers;
    private readonly utils: ITwoKeyUtils;


    constructor(twoKeyProtocol: ITwoKeyBase, helpers: ITwoKeyHelpers, utils: ITwoKeyUtils) {
        this.base = twoKeyProtocol;
        this.helpers = helpers;
        this.utils = utils;
    }

    public createWeightedVoteContract(data: ITwoKeyWeightedVoteConstructor, from: string,  { gasPrice, progressCallback, interval, timeout = 60000 }: ICreateOpts = {}) : Promise<string> {
        return new Promise(async(resolve, reject) => {
            try {
                let txHash = await this.helpers._createContract(contracts.TwoKeyWeightedVoteContract ,from, {params: [
                        data.descriptionForVoting,
                        data.addressOfDAO,
                        data.erc20
                    ],
                        gasPrice,
                        progressCallback
                    },

                );
                let receipt = await this.utils.getTransactionReceiptMined(txHash, { interval, timeout, web3: this.base.web3 });
                let address = receipt.contractAddress;
                resolve(address);
            } catch (e) {
                reject(e);
            }
        })
    }

}

export { ITwoKeyWeightedVoteContract } from './interfaces';
