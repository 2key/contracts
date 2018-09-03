import ipfsAPI from 'ipfs-api';
import { BigNumber } from 'bignumber.js';
import solidityContracts from './contracts/meta';
import { ERC20 } from './contracts/ERC20';
import { TwoKeyEconomy } from './contracts/TwoKeyEconomy';
import { TwoKeyEventSource } from './contracts/TwoKeyEventSource';
import { TwoKeyReg } from './contracts/TwoKeyReg';
import { TwoKeyCampaign } from './contracts/TwoKeyCampaign';
import { TwoKeyCampaignInventory } from './contracts/TwoKeyCampaignInventory';
import { TwoKeyCampaignETHCrowdsale } from './contracts/TwoKeyCampaignETHCrowdsale';
import {
  EhtereumNetworks,
  ContractsAdressess,
  TwoKeyInit,
  BalanceMeta,
  Transaction,
  CreateCampaign,
  Contract,
  RawTransaction,
} from './interfaces';
import Sign from './sign';
// import HDWalletProvider from './HDWalletProvider';

const contracts = require('./contracts.json');
// console.log(Sign);
// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
  ipfsIp: '192.168.47.99',
  ipfsPort: '5001',
  mainNetId: 4,
  syncTwoKeyNetId: 17,
};

export default class TwoKeyNetwork {
  private web3: any;
  private syncWeb3: any;
  private ipfs: any;
  private address: string;
  private gasPrice: number;
  private totalSupply: BigNumber;
  private gas: number;
  private networks: EhtereumNetworks;
  private contracts: ContractsAdressess;
  private twoKeyEconomy: TwoKeyEconomy;
  private twoKeyReg: TwoKeyReg;

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
    this.web3.eth.defaultBlock = 'pending';
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

    this.twoKeyEconomy = new TwoKeyEconomy(this.web3, this._getContractDeployedAddress('TwoKeyEconomy'));
    this.twoKeyReg = new TwoKeyReg(this.web3, this._getContractDeployedAddress('TwoKeyReg'));
    // this.twoKeyEventSource = new 

    // init 2KeySyncNet Client
    // const syncEngine = new ProviderEngine();
    // this.syncWeb3 = new Web3(syncEngine);
    // const syncProvider = new WSSubprovider({ rpcUrl: syncUrl });
    // syncEngine.addProvider(syncProvider);
    // syncEngine.start();
    this.ipfs = ipfsAPI(ipfsIp, ipfsPort, { protocol: 'http' });
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

  public getBalance(address: string = this.address): Promise<BalanceMeta> {
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
              total: parseFloat(this._fromWei(total.toString())),
              '2KEY': parseFloat(token),
            },
            local_address: this.address,
            gasPrice: parseFloat(gasPrice),
          });
        })
        .catch(reject)
    });
  }

  public getERC20TransferGas(to: string, value: number): Promise<number> {
    this.gas = null;
    return new Promise((resolve, reject) => {
      this.twoKeyEconomy.transferTx(to, this._toWei(value, 'ether')).estimateGas({ from: this.address })
        .then(res => {
          this.gas = res;
          resolve(this.gas);
        })
        .catch(reject);
    });
  }

  public getETHTransferGas(to: string, value: number): Promise<number> {
    this.gas = null;
    return new Promise((resolve, reject) => {
      this.web3.eth.estimateGas({ to, value: this._toWei(value, 'ether').toString() }, (err, res) => {
        if (err) {
          reject(err);
        } else {
          this.gas = res;
          resolve(this.gas);
        }
      });
    });
  }

  public async transferTokens(to: string, value: number, gasPrice: number = this.gasPrice): Promise<any> {
    const balance = parseFloat(await this._getEthBalance(this.address));
    const tokenBalance = parseFloat(await this._getTokenBalance(this.address));
    const gasRequired = await this.getERC20TransferGas(to, value);
    const etherRequired = parseFloat(this._fromWei(gasPrice * gasRequired, 'ether'));
    if (tokenBalance < value || balance < etherRequired) {
      throw new Error('Not enough founds');
    }
    const params = { from: this.address, gasLimit: this._toHex(this.gas), gasPrice };
    return this.twoKeyEconomy.transferTx(to, this._toWei(value, 'ether')).send(params);
  }

  public async transferEther(to: string, value: number, gasPrice: number = this.gasPrice): Promise<any> {
    const balance = parseFloat(await this._getEthBalance(this.address));
    const gasRequired = await this.getETHTransferGas(to, value);
    const totalValue = value + parseFloat(this._fromWei(gasPrice * gasRequired, 'ether'));
    if (totalValue > balance) {
      throw new Error('Not enough founds');
    }
    const params = { to, gasPrice, gasLimit: this._toHex(this.gas), value: this._toWei(value, 'ether').toString(), from: this.address }
    return new Promise((resolve, reject) => {
      this.web3.eth.sendTransaction(params, async (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(res);
        }
      });
    });
  }

  public estimateSaleCampaign(data: CreateCampaign): Promise<number> {
    return new Promise(async (resolve, reject) => {
      try {
        const whiteListGas = await this._estimateSubcontractGas(solidityContracts.TwoKeyWhitelisted);
        console.log('TwoKeyWhiteList', whiteListGas);
        const inventoryGas = await this._estimateSubcontractGas(solidityContracts.TwoKeyCampaignInventory, [data.openingTime, data.closingTime]);
        console.log('TwoKeyCampaignInventory', whiteListGas);
        const campaignGas = await this._estimateSubcontractGas(solidityContracts.TwoKeyCampaign, [
          this._getContractDeployedAddress('TwoKeyEventSource'),
          this.twoKeyEconomy.address,
          // Fake WhiteListInfluence address
          this.twoKeyEconomy.address,
          // Fake WhiteListConverter address
          this.twoKeyEconomy.address,
          this.twoKeyEconomy.address,
          data.contractor || this.address,
          data.moderator || this.address,
          data.openingTime,
          data.closingTime,
          data.expiryConversion,
          data.bonusOffer,
          data.rate,
          data.maxCPA,
        ]);
        console.log('TwoKeyCampaign', campaignGas);
        const totalGas = whiteListGas * 2 + inventoryGas + campaignGas;
        resolve(totalGas);
      } catch (err) {
        reject(err);
      }
    });
  }

  public createSaleCampaign(data: CreateCampaign, gasPrice?: number): Promise<string[]> {
    return new Promise(async (resolve, reject) => {
      try {
        const gasRequired = await this.estimateSaleCampaign(data);
        const balance = parseFloat(await this._getEthBalance(this.address));
        const transactionFee = parseFloat(this._fromWei(gasPrice || this.gasPrice * gasRequired, 'ether'));

        if (transactionFee > balance) {
          throw new Error('Not enough founds');
        }
        console.log('Creating TwoKeyWhitelisted...');
        const whitelistInfluencerAddress = await this._createContract(solidityContracts.TwoKeyWhitelisted);
        console.log('whitelistInfluencerAddress', whitelistInfluencerAddress);
        console.log('Creating TwoKeyWhitelisted...');
        const whitelistConverterAddress = await this._createContract(solidityContracts.TwoKeyWhitelisted);
        console.log('whitelistConverterAddress', whitelistConverterAddress);
        console.log('Creating TwoKeyCampaignInventory...');
        const campaignInventoryAddress = await this._createContract(solidityContracts.TwoKeyCampaignInventory, gasPrice, [data.openingTime, data.closingTime]);
        console.log('campaignInventoryAddress', campaignInventoryAddress);
        console.log('Creating TwoKeyCampaign...');
        const campaignAddress = await this._createContract(solidityContracts.TwoKeyCampaign, gasPrice, [
          this._getContractDeployedAddress('TwoKeyEventSource'),
          this.twoKeyEconomy.address,
          whitelistInfluencerAddress,
          whitelistConverterAddress,
          campaignInventoryAddress,
          data.contractor || this.address,
          data.moderator || this.address,
          data.openingTime,
          data.closingTime,
          data.expiryConversion,
          data.bonusOffer,
          data.rate,
          data.maxCPA,
        ]);
        const campaign = new TwoKeyCampaign(this.web3, campaignAddress);
        resolve([campaign.address, campaignInventoryAddress]);
      } catch (err) {
        reject(err);
      }
    });
  }

  // public getContractorCampaigns(): Promise<string[]> {
  //   return this.twoKeyReg.getContractsWhereUserIsContractor(this.address)
  // }

  public estimateAddFungibleInventory(inventoryAddress: string, erc20Address: string, amount: number, token: number = 1): Promise<number> {
    return new Promise(async (resolve, reject) => {
      try {
        const erc20 = await ERC20.createAndValidate(this.web3, erc20Address);
        const inventory = await TwoKeyCampaignInventory.createAndValidate(this.web3, inventoryAddress);
        const approveGas = await erc20.approveTx(inventoryAddress, amount).estimateGas({ from: this.address });
        console.log('Approve gas', approveGas);
        const addFungibleGas = await inventory.addFungibleAssetTx(token, erc20Address, amount).estimateGas({ from: this.address });
        console.log('Fungible gas', addFungibleGas);
        // const [approveGas, addFungibleGas] = await Promise.all([erc20.approveTx(inventoryAddress, amount).estimateGas({ from: this.address }), inventory.addFungibleAssetTx(token, erc20Address, amount).estimateGas({ from: this.address })]);
        resolve(approveGas + addFungibleGas);
      } catch (err) {
        reject(err);
      }
    });
  }

  public async addFungibleInventory(inventoryAddress: string, erc20Address: string, amount: number, token: number = 1, gasPrice: number = this.gasPrice): Promise<any> {
    // const gasRequired = await this.estimateAddFungibleInventory(inventoryAddress, erc20Address, amount, token);
    // const balance = parseFloat(await this._getEthBalance(this.address));
    // const transactionFee = parseFloat(this._fromWei(gasPrice || this.gasPrice * gasRequired, 'ether'));
    // console.log('Gas Required', transactionFee);
    // if (transactionFee > balance) {
    //   throw new Error('Not enough founds');
    // }

    const erc20 = await ERC20.createAndValidate(this.web3, erc20Address);
    const inventory = await TwoKeyCampaignInventory.createAndValidate(this.web3, inventoryAddress);
    const approve = await erc20.approveTx(inventoryAddress, amount).send({ from: this.address, gasPrice });
    console.log('Approve', approve);
    console.time('Mined');
    await this._waitForTransactionMined(approve);
    console.timeEnd('Mined');
    return inventory.addFungibleAssetTx(token, erc20Address, amount).send({ from: this.address, gasPrice, gas: 200000 })
  }

  public async getFungibleInventory(erc20Address, inventoryAddress): Promise<any> {
    const erc20 = new ERC20(this.web3, erc20Address);
    return new Promise(async (resolve, reject) => {
      try {
        const inventory = await erc20.balanceOf(inventoryAddress);
        resolve(inventory.toNumber());
      } catch (err) {
        reject(err);
      }
    });
  }

  public async getContractorCampaigns(): Promise<any> {
    const eventSource = await TwoKeyEventSource.createAndValidate(this.web3, this._getContractDeployedAddress('TwoKeyEventSource'));
    // return eventSource.CreatedEvent({ _owner: this.address }).get({ fromBlock: 0, toBlock: 'pending' });
    return eventSource.CreatedEvent({}).get({ fromBlock: 0, toBlock: 'pending' });
  }

  public setHandle(handle: string, gasPrice: number = this.gasPrice): Promise<string> {
    // const registry = this.web3.eth.contract(contracts.TwoKeyReg.abi).at(this._getContractDeployedAddress('TwoKeyReg'));
    // const data = registry.addName.getData(handle, this.address);
    // // const data = this.twoKeyReg.addNameTx(handle, this.address).getData();
    // console.log(data);
    // const tx = {
    //   from: this.address,
    //   data,
    //   to: this.twoKeyReg.address,
    //   value: '0x0',
    //   gas: 10000000
    // };
    // const gas = await this._estimateTransactionGas(tx);
    // // const gas = await this.twoKeyReg.addNameTx(handle, this.address).estimateGas({ from: this.address });
    // const balance = parseFloat(await this._getEthBalance(this.address));
    // const transactionFee = parseFloat(this._fromWei(gasPrice * gas, 'ether'));
    // console.log('Gas Required', transactionFee);
    // if (transactionFee > balance) {
    //   throw new Error('Not enough founds');
    // }
    return this.twoKeyReg.addNameTx(handle, this.address).send({ from: this.address, gasPrice, gas: 2000000 });
    // return new Promise(async (resolve, reject) => {
    //   try {
    //     const txHash = await this.twoKeyReg.addNameTx(handle, this.address).send({ from: this.address, gasPrice, gas: 2000000 })
    //     await this._waitForTransactionMined(txHash);
    //     const result = await this.twoKeyReg.getOwner2Name(this.address);
    //     resolve(result);
    //   } catch (err) {
    //     reject(err);
    //   }
    // });
  }

  public getAddressHandle(address: string = this.address): Promise<string> {
    // return this.twoKeyReg.getOwner2Name(address);
    return this.twoKeyReg.getName2Owner(address);
  }

  public joinCampaign(campaignAddress?: string, cut?: number, fromHash?: string): Promise<string> {
    let pk = Sign.generatePrivateKey();
    let public_address = Sign.privateToPublic(pk);
    const private_key = pk.toString('hex');
  
    return new Promise(async (resolve, reject) => {
      let new_message;
      if (fromHash) {
        const { f_address, f_secret, p_message } = this._getUrlParams(fromHash);
        new_message = Sign.free_join(this.address, public_address, f_address, f_secret, p_message, cut);
        // this.ipfs.cat(fromHash, async (err, decodedUrl) => {
        //   if (err) {
        //     reject(err);
        //   } else {
        //     // console.log(decodedUrl.toString());
        //     // resolve(decodedUrl.toString());
        //     const [f_address, f_secret, p_message] = JSON.parse(decodedUrl.toString());
        //     // const [f_address, f_secret, p_message] = JSON.parse(`{"${decodeURI(decodedUrl.toString())
        //     //   .replace(/"/g, '\\"').replace(/&/g, '","').replace(/=/g, '":"')}"}`);
        //     console.log(f_address, f_secret, p_message);
        //     new_message = Sign.free_join(this.address, public_address, f_address, f_secret, p_message, cut);
        //     try {
        //       const hash = await this._ipfsAdd([this.address, private_key, new_message]);
        //       resolve(hash);
        //     } catch (error) {
        //       reject(error);
        //     }
        //   }
        // });
        // const { f_address, f_secret, p_message } = fromHash;
      } else {
        // resolve(`f_address=${this.address}&$f_secret=${private_key}&p_message=${new_message}`);
        // try {
        //   const hash = this._ipfsAdd([this.address, private_key, new_message]);
        //   resolve(hash);
        // } catch (err) {
        //   reject(err);
        // }
      }
      resolve(`f_address=${this.address}&f_secret=${private_key}&p_message=${new_message || ''}`);
      // resolve('hash');
    });
  }

  private _fromWei(number: string | number | BigNumber, unit?: string): string {
    return this.web3.fromWei(number, unit);
  }

  private _toWei(number: string | number | BigNumber, unit?: string): number | BigNumber {
    return this.web3.toWei(number, unit);
  }

  private _toHex(data: any): string {
    return this.web3.toHex(data);
  }

  private _getContractDeployedAddress(contract: string): string {
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
          resolve(this._fromWei(res.toString(), 'ether'));
        }
      })
    })
  }

  private _getTokenBalance(address: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.twoKeyEconomy.balanceOf(address)
        .then(res => {
          resolve(this._fromWei(res.toString()))
        })
        .catch(reject);
    });
  }

  private _getTotalSupply(): Promise<string> {
    if (this.totalSupply) {
      return Promise.resolve(this._fromWei(this.totalSupply.toString()));
    }
    return new Promise((resolve, reject) => {
      this.twoKeyEconomy.totalSupply
        .then(res => {
          this.totalSupply = res;
          resolve(this._fromWei(this.totalSupply.toString()));
        })
        .catch(reject);
    });
  }

  public _getTransaction(txHash: string): Promise<Transaction> {
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

  private _createContract(contract: Contract, gasPrice: number = this.gasPrice, params?: any[]): Promise<string> {
    return new Promise(async (resolve, reject) => {
      const { abi, bytecode: data } = contract;
      const gas = await this._estimateSubcontractGas(contract, params);
      const createParams = params ? [...params, { data, from: this.address, gas, gasPrice }] : [{ data, from: this.address, gas, gasPrice }];
      this.web3.eth.contract(abi).new(...createParams, (err, res) => {
        if (err) {
          reject(err);
        } else {
          if (res.address) {
            resolve(res.address);
          } else {
            console.log('Transaction Hash:', res.transactionHash);
          }
        }
      });
    });
  }

  private _estimateSubcontractGas(contract: Contract, params?: any[]): Promise<number> {
    return new Promise(async (resolve, reject) => {
      const { abi, bytecode: data } = contract;
      const estimateParams = params ? [...params, { data, from: this.address }] : [{ data, from: this.address }];
      this.web3.eth.estimateGas({
        data: this.web3.eth.contract(abi).new.getData(...estimateParams),
      }, (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(res);
        }
      })
    });
  }

  private _estimateTransactionGas(data: RawTransaction): Promise<number> {
    return new Promise((resolve, reject) => {
      this.web3.eth.estimateGas(data, (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(res);
        }
      });
    });
  }

  private _getNonce(): Promise<number> {
    return new Promise((resolve, reject) => {
      this.web3.eth.getTransactionCount(this.address, 'pending', (err, res) => {
        if (err) {
          reject(err);
        } else {
          // console.log('NONCE', res, this.address);
          resolve(res);
        }
      });
    });
  }

  private _getBlock(block: string | number): Promise<Transaction> {
    return new Promise((resolve, reject) => {
      this.web3.eth.getBlock(block, (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(res);
        }
      });
    });
  }

  private _waitForTransactionMined(txHash: string, timeout: number = 60000): Promise<boolean> {
    return new Promise((resolve, reject) => {
      let fallbackTimer;
      let interval;
      fallbackTimer = setTimeout(() => {
        if (interval) {
          clearInterval(interval);
          interval = null;
        }
        if (fallbackTimer) {
          clearTimeout(fallbackTimer);
          fallbackTimer = null;
        }
        reject();
      }, timeout);
      interval = setInterval(async () => {
        let tx = await this._getTransaction(txHash);
        if (tx.blockNumber) {
          if (fallbackTimer) {
            clearTimeout(fallbackTimer);
            fallbackTimer = null;
          }
          if (interval) {
            clearInterval(interval);
            interval = null;
          }
          resolve(true);
        }
      }, 1000);
    });
  }

  private _ipfsAdd(data: any): Promise<string> {
    return new Promise((resolve, reject) => {
      this.ipfs.add([Buffer.from(JSON.stringify(data))], (err, res) => {
        if (err) {
          reject(err);
        } else {
          resolve(res[0].hash);
        }
      });  
    })
  }

  private _getUrlParams(url: string): any {
    let hashes = url.slice(url.indexOf('?') + 1).split('&');
    let params = {};
    hashes.map(hash => {
        let [key, val] = hash.split('=')
        params[key] = decodeURIComponent(val);
    })
    return params;
  }
}
