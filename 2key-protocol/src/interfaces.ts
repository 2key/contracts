import {BigNumber} from 'bignumber.js';

export interface ITwoKeyBase {
    readonly web3: any;
    readonly syncWeb3: any;
    readonly ipfs: any;
    readonly address: string;
    readonly networks: IEhtereumNetworks;
    readonly contracts: IContractsAddresses;
    readonly twoKeyEconomy: any;
    readonly twoKeyEventContract: any;
    readonly eventsAddress: string;
    readonly _setGasPrice: (number) => void,
    readonly _getGasPrice: () => number,
    readonly _setTotalSupply: (number) => void,
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
    _createContract: (contract: IContract, gasPrice?: number, params?: any[], progressCallback?: ICreateCampaignProgress) => Promise<string>,
    _estimateSubcontractGas: (contract: IContract, params?: any[]) => Promise<number>,
    _estimateTransactionGas: (data: IRawTransaction) => Promise<number>,
    _getUrlParams: (url: string) => any,
    _checkBalanceBeforeTransaction: (gasRequired: number, gasPrice: number) => Promise<boolean>,
    _getAcquisitionCampaignInstance: (campaign: any) => Promise<any>,
    _createAndValidate: (contractName: string, address: string) => Promise<any>,
    _checkIPFS: () => Promise<boolean>,
}

export interface ITwoKeyAcquisitionCampaign {
    estimateCreation: (data: IAcquisitionCampaign) => Promise<number>,
    create: (data: IAcquisitionCampaign, progressCallback?: ICreateCampaignProgress, gasPrice?: number) => Promise<string>,
    checkInventoryBalance: (campaign: any) => Promise<number>,
    getPublicLinkKey: (campaign: any, address?: string) => Promise<string>,
    getReferrerCut: (campaign: any) => Promise<number>,
    setAcquisitionPublicLinkKey: (campaign: any, publicKey: string, gasPrice?: number) => Promise<string>,
    getEstimatedMaximumReferralReward: (campaign: any, referralLink?: string) => Promise<number>,
    emitAcquisitionCampaignJoinEvent: (campaignAddress: string, referralLink: string) => Promise<string>,
    join: (campaign: any, cut: number, referralLink?: string, gasPrice?: number) => Promise<string>,
    joinAndSetPublicLinkWithCut: (campaignAddress: string, referralLink: string, cut?: number, gasPrice?: number) => Promise<string>,
    joinAndShareARC: (campaignAddress: string, referralLink: string, recipient: string, gasPrice?: number) => Promise<string>,
    joinAndConvert: (campaign: any, value: number | string | BigNumber, referralLink: string, gasPrice?: number) => Promise<string>,
    getAcquisitionConverterConversion: (campaign: any, address?: string) => Promise<any>,
    getTwoKeyConversionHandlerAddress: (campaign: any) => Promise<string>,
    getAssetContractData: (campaign: any) => Promise<any>,
}

export interface ITWoKeyUtils {
    ipfsAdd: (data: any) => Promise<string>,
    fromWei: (number: number | string | BigNumber, unit?: string) => string | BigNumber,
    toWei: (number: string | number | BigNumber, unit?: string) => BigNumber,
    toHex: (data: any) => string,
    getBalanceOfArcs: (campaign: any, address?: string) => Promise<number>,
    balanceFromWeiString: (meta: BalanceMeta, inWei?: boolean, toNum?: boolean) => IBalanceNormalized,
    getTransactionReceiptMined: (txHash: string, web3?: any, interval?: number, timeout?: number) => Promise<ITransactionReceipt>
}

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

export interface IContractsAddresses {
    TwoKeyEconomy?: string
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

export interface IEhtereumNetworks {
    mainNetId: number | string,
    syncTwoKeyNetId: number | string,
}

export interface ITwoKeyInit {
    web3: any,
    address: string,
    ipfsIp?: string,
    ipfsPort?: string | number,
    contracts?: IContractsAddresses,
    networks?: IEhtereumNetworks,
    eventsNetUrl?: string,
    reportKey?: string,
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

export interface IAcquisitionCampaign {
    moderator?: string, // Address of the moderator - it's a contract that works (operates) as admin of whitelists contracts
    assetContractERC20: string,
    campaignStartTime: number, // Timestamp
    campaignEndTime: number, // Timestamp
    expiryConversion: number, // Timestamp
    moderatorFeePercentageWei: number | string | BigNumber,
    maxReferralRewardPercentWei: number | string | BigNumber,
    maxConverterBonusPercentWei: number | string | BigNumber,
    pricePerUnitInETHWei: number | string | BigNumber,
    minContributionETHWei: number | string | BigNumber,
    maxContributionETHWei: number | string | BigNumber,
    referrerQuota?: number,
    tokenDistributionDate: number,
    maxDistributionDateShiftInDays: number,
    bonusTokensVestingMonths: number,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: number
}

export interface ICreateCampaignProgress {
    (contract: string, mined: boolean, transactionResult: string): void;
}

export interface IContract {
    name: string,
    abi: any,
    bytecode: string,
}

export interface IContractEvent {
    address: string,
    args: any,
    blockHash: string,
    blockNumber: number,
    logIndex: number,
    event: string,
    removed: boolean,
    transactionIndex: number,
    transactionHash: string,
}
