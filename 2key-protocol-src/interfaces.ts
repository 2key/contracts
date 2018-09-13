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
  mainNetId: number | string,
  syncTwoKeyNetId: number | string,
}

export interface TwoKeyInit {
  web3: Web3,
  ipfsIp?: string,
  ipfsPort?: string | number,
  contracts?: ContractsAdressess,
  networks?: EhtereumNetworks,
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

export interface RawTransaction {
  from?: string;
  gas?: number;
  gasPrice?: number;
  to: string;
  value?: string;
  data?: string;
}

export interface AcquisitionCampaign {
  eventSource: string, // Address of TwoKeyEvent source
  twoKeyEconomy: string, // Address of TwoKeyEconomy
  moderator?: string, // Address of the moderator - it's a contract that works (operates) as admin of whitelists contracts
  openingTime: number, // Timestamp
  closingTime: number, // Timestamp
  expiryConversion: number, // Timestamp
  bonusOffer?: number,
  rate?: number,
  maxCPA?: number,
  erc20address: string,
  quota?: number,
}

export interface CreateCampignProgress {
  (contract: string, mined: boolean, transactionResult: string): void;
}
export interface Contract {
  name: string,
  abi: any,
  bytecode: string,
}