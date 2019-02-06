import {BigNumber} from 'bignumber.js';
import {ICreateCampaignProgress,} from '../interfaces';

interface IBalance {
    ETH: number | string | BigNumber,
    total: number | string | BigNumber,
    '2KEY': number | string | BigNumber,
}

export interface BalanceMeta {
    balance: IBalance,
    local_address: string,
    gasPrice: number | string | BigNumber,
}

export interface IBalanceNormalized {
    balance: {
        ETH: string | number,
        total: string | number,
        '2KEY': string | number,
    },
    local_address: string,
    gasPrice: string | number,
}

export interface IOffchainData {
    campaign: string,
    contractor?: string,
    f_address: string,
    f_secret: string,
    p_message?: string,
    dao?: string,
}

export interface ITransaction {
    hash: string;
    nonce: number;
    blockHash: string;
    blockNumber: number;
    transactionIndex: number;
    from: string;
    to: string;
    value: string;
    gasPrice: string;
    gas: number;
    input: string;
    v?: string;
    r?: string;
    s?: string;
}

export interface ITransactionReceipt {
    blockHash: string;
    blockNumber: number;
    transactionHash: string;
    transactionIndex: number;
    from: string;
    to: string | null;
    cumulativeGasUsed: number;
    gasUsed: number;
    contractAddress: string | null;
    logs: any[];
    status: string;
}

export interface IRawTransaction {
    from?: string;
    gas?: number;
    gasPrice?: number;
    to: string;
    value?: string | BigNumber;
    data?: string;
}

export interface IContract {
    name: string,
    abi: any,
    bytecode: string,
}

export interface IPlasmaSignature {
    sig: string,
    with_prefix: boolean,
}

export interface ISignedKeys {
    private_key: string,
    public_address: string,
}

export interface ITwoKeyHelpers {
    _normalizeString: (value: number | string | BigNumber, inWei: boolean) => string,
    _normalizeNumber: (value: number | string | BigNumber, inWei: boolean) => number,
    _getContractDeployedAddress: (contract: string) => string,
    _getGasPrice: () => Promise<number | string | BigNumber>,
    _getEthBalance: (address: string) => Promise<number | string | BigNumber>,
    _getTokenBalance: (address: string, erc20address?: string) => Promise<number | string | BigNumber>,
    _getTotalSupply: (erc20address?: string) => Promise<number | string | BigNumber>,
    _getTransaction: (txHash: string) => Promise<ITransaction>,
    _createContract: (contract: IContract, from: string, opts?: ICreateContractOpts) => Promise<string>,
    _estimateSubcontractGas: (contract: IContract, from: string, params?: any[]) => Promise<number>,
    _estimateTransactionGas: (data: IRawTransaction) => Promise<number>,
    _getUrlParams: (url: string) => any,
    _checkBalanceBeforeTransaction: (gasRequired: number, gasPrice: number, from: string) => Promise<boolean>,
    _getAcquisitionCampaignInstance: (campaign: any) => Promise<any>,
    _getAcquisitionConversionHandlerInstance: (campaign: any) => Promise<any>
    _getAcquisitionLogicHandlerInstance: (campaign: any) => Promise<any>
    _getAirdropCampaignInstance: (campaign: any) => Promise<any>,
    _getWeightedVoteContract: (campaign: any) => Promise<any>,
    _getERC20Instance: (erc20: any) => Promise<any>,
    _getTwoKeyAdminInstance(twoKeyAdmin: any) : Promise<any>,
    _getTwoKeyCongressInstance(congress: any) : Promise<any>,
    _getDecentralizedNationInstance(decentralizedNation: any) : Promise<any>,
    _getLockupContractInstance(twoKeyLockup: any) : Promise<any>,
    _getUpgradableExchangeInstance(upgradableExchange: any) : Promise<any>,
    _createAndValidate: (contractName: string, address: string) => Promise<any>,
    _checkIPFS: () => Promise<boolean>,
    _getNonce: (from: string) => Promise<number>,
    _awaitPlasmaMethod: (plasmaPromiseMethod: Promise<any>, timeout?: number) => Promise<any>,
}

export interface ITwoKeyUtils {
    transferEther: (to: string, value: number | string | BigNumber, from: string) => Promise<string>
    ipfsAdd: (data: any) => Promise<string>,
    getOffchainDataFromIPFSHash: (hash: string) => Promise<IOffchainData>,
    fromWei: (number: number | string | BigNumber, unit?: string | number) => string | BigNumber,
    toWei: (number: string | number | BigNumber, unit?: string | number) => BigNumber,
    toHex: (data: any) => string,
    balanceFromWeiString: (meta: BalanceMeta, opts?: IBalanceFromWeiOpts) => IBalanceNormalized,
    getTransactionReceiptMined: (txHash: string, opts?: ITxReceiptOpts) => Promise<ITransactionReceipt>,
}

export interface ILink {
    name: string,
    address: string,
}

export interface ICreateContractOpts {
    gasPrice?: number,
    nonce?: number,
    params?: any[],
    progressCallback?: ICreateCampaignProgress,
    link?: ILink,
}

export interface IBalanceFromWeiOpts {
    inWei?: boolean,
    toNum?: boolean,
}

export interface ITxReceiptOpts {
    web3?: any,
    interval?: number,
    timeout?: number,
}
