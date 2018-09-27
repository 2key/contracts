import {BigNumber} from 'bignumber.js';

interface Balance {
    ETH: number | string | BigNumber,
    total: number | string | BigNumber,
    '2KEY': number | string | BigNumber,
}

export interface BalanceMeta {
    balance: Balance,
    local_address: string,
    gasPrice: number | string | BigNumber,
}

export interface ContractsAdressess {
    TwoKeyEconomy?: string
}

export interface BalanceNormalized {
    balance: {
        ETH: string | number,
        total: string | number,
        '2KEY': string | number,
    },
    local_address: string,
    gasPrice: string | number,
}

export interface EhtereumNetworks {
    mainNetId: number | string,
    syncTwoKeyNetId: number | string,
}

export interface TwoKeyInit {
    web3: any,
    address: string,
    ipfsIp?: string,
    ipfsPort?: string | number,
    contracts?: ContractsAdressess,
    networks?: EhtereumNetworks,
    eventsNetUrl?: string,
    reportKey?: string,
}

export interface Transaction {
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

export interface TransactionReceipt {
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

export interface RawTransaction {
    from?: string;
    gas?: number;
    gasPrice?: number;
    to: string;
    value?: string | BigNumber;
    data?: string;
}

export interface AcquisitionCampaign {
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
}

export interface CreateCampignProgress {
    (contract: string, mined: boolean, transactionResult: string): void;
}

export interface Contract {
    name: string,
    abi: any,
    bytecode: string,
}

export interface ContractEvent {
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
