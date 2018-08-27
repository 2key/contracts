import { BigNumber } from 'bignumber.js';

interface Balance {
  ETH: number,
  total: number,
  '2KEY': number,
};

export interface BalanceMeta {
  balance: Balance,
  local_address: string,
  gasPrice: number,
}

export interface ContractsAdressess {
  TwoKeyEconomy?: string
}

export interface EhtereumNetworks {
  mainNetId: number,
  syncTwoKeyNetId: number,
}

export interface TwoKeyInit {
  rpcUrl?: string,
  wsUrl?: string,
  syncUrl?: string,
  ipfsIp?: string,
  ipfsPort?: string | number,
  wallet: any,
  contracts?: ContractsAdressess,
  networks?: EhtereumNetworks,
}

export interface Gas {
  wei: number,
}

export interface Transaction {
  hash: string,
  nonce: number,
  blockHash: string,
  blockNumber: number,
  transactionIndex: number,
  from: string,
  to: string,
  value: BigNumber,
  gas: number,
  gasPrice: BigNumber,
  input: string
}

export interface RawTransaction {
  from?: string;
  gas?: number;
  gasPrice?: number;
  to: string;
  value?: string;
  data?: string;
}