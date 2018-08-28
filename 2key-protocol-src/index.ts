import ipfsAPI from 'ipfs-api';
import { BigNumber } from 'bignumber.js';
import solidityContracts from './contracts/meta';
import { TwoKeyEconomy } from './contracts/TwoKeyEconomy';
import { TwoKeyCampaign } from './contracts/TwoKeyCampaign';
import { TwoKeyWhitelisted } from './contracts/TwoKeyWhitelisted';
import { TwoKeyARC } from './contracts/TwoKeyARC';
import { ComposableAssetFactory } from './contracts/ComposableAssetFactory';
import { EhtereumNetworks, ContractsAdressess, TwoKeyInit, BalanceMeta, Gas, Transaction, CreateCampaign } from './interfaces';
import Sign from './sign';
// import HDWalletProvider from './HDWalletProvider';

// console.log(Sign);
// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
  ipfsIp: '192.168.47.100',
  ipfsPort: '5001',
  mainNetId: 4,
  syncTwoKeyNetId: 17,
};

export default class TwoKeyNetwork {
  private web3: any;
  private syncWeb3: any;
  private ipfs: ipfsAPI;
  private address: string;
  private gasPrice: number;
  private totalSupply: BigNumber;
  private gas: number;
  private networks: EhtereumNetworks;
  private contracts: ContractsAdressess;
  private twoKeyEconomy: TwoKeyEconomy;

  constructor(initValues: TwoKeyInit) {
    // init MainNet Client
    const {
      web3,
      // syncUrl = TwoKeyDefaults.twoKeySyncUrl,
      ipfsIp = TwoKeyDefaults.ipfsIp,
      ipfsPort = TwoKeyDefaults.ipfsPort,
      contracts,
      networks,
    } = initValues;
    if (!web3) {
      throw new Error('Web3 instanse required!');
    }
    if (!web3.eth.defaultAccount) {
      throw new Error('defaultAccount required!');
    }
    this.web3 = web3;
    this.address = this.web3.eth.defaultAccount;
    if (contracts) {
      this.contracts = contracts;
    } else if (networks) {
      this.networks = networks;
    } else {
      this.networks = {
        mainNetId: TwoKeyDefaults.mainNetId,
        syncTwoKeyNetId: TwoKeyDefaults.syncTwoKeyNetId,
      }
    }
    this.web3.eth.defaultBlock = 'pending';
    // this.pk = wallet.getPrivateKey().toString('hex');

    this.twoKeyEconomy = new TwoKeyEconomy(this.web3, this.getContractDeployedAddress('TwoKeyEconomy'))

    // init 2KeySyncNet Client
    // const syncEngine = new ProviderEngine();
    // this.syncWeb3 = new Web3(syncEngine);
    // const syncProvider = new WSSubprovider({ rpcUrl: syncUrl });
    // syncEngine.addProvider(syncProvider);
    // syncEngine.start();
    // this.ipfs = ipfsAPI(ipfsIp, ipfsPort, { protocol: 'http' });
  }

  public getGasPrice(): number {
    return this.gasPrice;
  }

  public getTotalSupply(): BigNumber {
    return this.totalSupply;
  }

  public getGas(): number {
    return this.gas;
  }

  public getAddress(): string {
    return this.address;
  }

  public fromWei(number: string | number | BigNumber, unit?: string): string {
    return this.web3.fromWei(number, unit);
  }

  public toWei(number: string | number | BigNumber, unit?: string): number | BigNumber {
    return this.web3.toWei(number, unit);
  }

  public toHex(data: any): string {
    return this.web3.toHex(data);
  }

  public getTransaction(txHash: string): Promise<Transaction> {
    return new Promise((resolve, reject) => {
      this.web3.eth.getTransaction(txHash, (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(res);
        }
      });
    });
  }

  public getBalance(address: string = this.address): Promise<BalanceMeta> {
    console.log('getBalance', address);
    const promises = [
      this._getEthBalance(address),
      this._getTokenBalance(address),
      this._getTotalSupply(),
      this._getGasPrice()
    ];
    return new Promise((resolve, reject) => {
      Promise.all(promises)
        .then(([eth, token, total, gasPrice]) => {
          resolve({
            balance: {
              ETH: parseFloat(eth),
              total: parseFloat(this.fromWei(total.toString())),
              '2KEY': parseFloat(token),
            },
            local_address: this.address,
            gasPrice: parseFloat(gasPrice),
          });
        })
        .catch(reject)
    });
  }

  public getERC20TransferGas(to: string, value: number): Promise<Gas> {
    this.gas = null;
    return new Promise((resolve, reject) => {
      this.twoKeyEconomy.transferTx(to, this.toWei(value, 'ether')).estimateGas({ from: this.address })
        .then(res => {
          this.gas = res;
          resolve({ wei: this.gas });
        })
        .catch(reject);
    });
  }

  public getETHTransferGas(to: string, value: number): Promise<Gas> {
    this.gas = null;
    return new Promise((resolve, reject) => {
      this.web3.eth.estimateGas({ to, value: this.toWei(value, 'ether').toString() }, (err, res) => {
        if (err) {
          reject(err);
        } else {
          this.gas = res;
          resolve({ wei: this.gas });
        }
      });
    });
  }

  public async transferTokens(to: string, value: number, gasPrice: number = this.gasPrice): Promise<string> {
    const balance = parseFloat(await this._getEthBalance(this.address));
    const tokenBalance = parseFloat(await this._getTokenBalance(this.address));
    const { wei: gasRequired } = await this.getERC20TransferGas(to, value);
    const etherRequired = parseFloat(this.fromWei(gasPrice * gasRequired, 'ether'));
    console.log(value, etherRequired);
    if (tokenBalance < value || balance < etherRequired) {
      throw new Error('Not enough founds');
    }

    const params = { from: this.address, gasLimit: this.toHex(this.gas), gasPrice };
    return this.twoKeyEconomy.transferTx(to, this.toWei(value, 'ether')).send(params);
  }

  public async transferEther(to: string, value: number, gasPrice: number = this.gasPrice): Promise<any> {
    const balance = parseFloat(await this._getEthBalance(this.address));
    const { wei: gasRequired } = await this.getETHTransferGas(to, value);
    const totalValue = value + parseFloat(this.fromWei(gasPrice * gasRequired, 'ether'));
    console.log(value, totalValue);
    if (totalValue > balance) {
      throw new Error('Not enough founds');
    }
    const params = { to, gasPrice, gasLimit: this.toHex(this.gas), value: this.toWei(value, 'ether').toString(), from: this.address }
    return new Promise((resolve, reject) => {
      this.web3.eth.sendTransaction(params, (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(res);
        }
      });
    });
  }

  public createSaleCampaign(data: CreateCampaign): Promise<string> {
    return new Promise((resolve, reject) => {
      resolve('qwerty');
    });
  }

  private getContractDeployedAddress(contract: string): string {
    return this.contracts ? this.contracts[contract] : solidityContracts[contract].networks[this.networks.mainNetId].address
  }

  private _getGasPrice(): Promise<string> {
    return new Promise((resolve, reject) => {
      this.web3.eth.getGasPrice((err, res) => {
        if (err) {
          reject(err);
        } else {
          this.gasPrice = res.toNumber();
          resolve(res.toString());
        }
      });
    });
  }

  private _getEthBalance(address: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.web3.eth.getBalance(address, this.web3.eth.defaultBlock, (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(this.fromWei(res.toString(), 'ether'));
        }
      })
    })
  }

  private _getTokenBalance(address: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.twoKeyEconomy.balanceOf(address)
        .then(res => {
          resolve(this.fromWei(res.toString()))
        })
        .catch(reject);
    });
  }

  private _getTotalSupply(): Promise<string> {
    if (this.totalSupply) {
      return Promise.resolve(this.fromWei(this.totalSupply.toString()));
    }
    return new Promise((resolve, reject) => {
      this.twoKeyEconomy.totalSupply
        .then(res => {
          this.totalSupply = res;
          resolve(this.fromWei(this.totalSupply.toString()));
        })
        .catch(reject);
    });
  }

  private _createWhiteList(): Promise<string> {
    return new Promise((resolve, reject) => {
      
    });
  }

  /*
  private _getNonce(): Promise<number> {
    return new Promise((resolve, reject) => {
      this.mainWeb3.eth.getTransactionCount(this.address, 'pending', (err, res) => {
        if (err) {
          reject(err);
        } else {
          console.log('NONCE', res, this.address);
          resolve(res);
        }
      });
    });
  }

  private _createRawTransaction(params: RawTransaction): Promise<string> {
    return new Promise(async (resolve, reject) => {
      try {
        const nonce = this.mainWeb3.toHex(await this._getNonce());
        const rawTransaction = {
          nonce: this.mainWeb3.toHex(nonce),
          from: params.from || this.address,
          gasLimit: this.mainWeb3.toHex(params.gas || this.gas),
          gasPrice: this.mainWeb3.toHex(params.gasPrice || this.gasPrice),
          to: params.to,
          value: params.value,
          data: params.data
        };
        const tx = new Tx(rawTransaction);
        tx.sign(Buffer.from(this.pk, 'hex'));
        const signedTransaction = `0x${tx.serialize().toString('hex')}`;
        resolve(signedTransaction);
      } catch (err) {
        reject(err);
      }
    });
  }

  private _sendRawTransaction(transaction: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.mainWeb3.eth.sendRawTransaction(transaction, (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(res);
        }
      })
    });
  }
  */
}
