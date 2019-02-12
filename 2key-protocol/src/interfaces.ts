export {IERC20} from './erc20/interfaces';
export {ITwoKeyCongress} from './congress/interfaces';
export {ITwoKeyAcquisitionCampaign, IOffchainData} from './acquisition/interfaces';
export {IDecentralizedNation} from './decentralizedNation/interfaces';
export {ITwoKeyReg} from './registry/interfaces';
export {IPlasmaEvents} from './plasma/interfaces';
export {ITwoKeyHelpers,ITwoKeyUtils,BalanceMeta} from './utils/interfaces';
export {IUpgradableExchange} from './upgradableExchange/interfaces';
export {ITwoKeyExchangeContract} from './exchangeETHUSD/interfaces';

export interface ITwoKeyBase {
    web3: any;
    plasmaWeb3: any;
    ipfsR: any;
    ipfsW: any;
    networks: IEhtereumNetworks;
    contracts: IContractsAddresses;
    twoKeySingletonesRegistry: any,
    twoKeyAdmin: any,
    twoKeyEventSource: any;
    twoKeyExchangeContract: any;
    twoKeyUpgradableExchange: any;
    twoKeyEconomy: any;
    twoKeyCall: any;
    twoKeyReg: any;
    twoKeyCongress: any;
    twoKeyPlasmaEvents: any;
    twoKeyBaseReputationRegistry: any;
    plasmaAddress: string;
    plasmaPrivateKey: string;
    _setGasPrice: (number) => void,
    _getGasPrice: () => number,
    _setTotalSupply: (number) => void,
    _log: any,
    nonSingletonsHash: string,
}

export interface ICreateOpts {
    progressCallback?: ICreateCampaignProgress,
    gasPrice?: number,
    interval?: number,
    timeout?: number
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
    ipfsRIp?: string,
    ipfsRPort?: string | number,
    ipfsRProtocol?: string,
    ipfsWIp?: string,
    ipfsWPort?: string | number,
    ipfsWProtocol?: string,
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
