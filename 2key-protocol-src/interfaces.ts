import { BigNumber } from 'bignumber.js';
import Web3 from 'web3';

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
  web3: Web3,
  ipfsIp?: string,
  ipfsPort?: string | number,
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