export {IERC20} from './erc20/interfaces';
export {ILockup} from './lockup/interfaces';
export {ITwoKeyCongress} from './congress/interfaces';
export {ITwoKeyAcquisitionCampaign} from './acquisition/interfaces';
export {ITwoKeyHelpers,ITwoKeyUtils,BalanceMeta,IOffchainData} from './utils/interfaces';

export interface ITwoKeyBase {
    web3: any;
    plasmaWeb3: any;
    ipfs: any;
    networks: IEhtereumNetworks;
    contracts: IContractsAddresses;
    twoKeyEconomy: any;
    twoKeyReg: any;
    twoKeyCongress: any;
    twoKeyPlasmaEvents: any;
    plasmaAddress: string;
    _setGasPrice: (number) => void,
    _getGasPrice: () => number,
    _setTotalSupply: (number) => void,
    _log: any,
}

// We need twoKeyAdmin in order to approve twoKeyAcquisitionCampaign to emit events
export interface ITwoKeyAdmin {

}

export interface IContractsAddresses {
    TwoKeyEconomy?: string
}

export interface IEhtereumNetworks {
    mainNetId: number | string,
    syncTwoKeyNetId: number | string,
}

export interface ITwoKeyInit {
    web3?: any,
    ipfsIp?: string,
    ipfsPort?: string | number,
    ipfsProtocol?: string,
    contracts?: IContractsAddresses,
    networks?: IEhtereumNetworks,
    rpcUrl?: string,
    eventsNetUrl?: string,
    plasmaPK: string,
    log?: (any) => void,
}

export interface ICreateCampaignProgress {
    (contract: string, mined: boolean, transactionResult: string): void;
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
