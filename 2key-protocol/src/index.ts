import ipfsAPI from 'ipfs-api';
import Web3 from 'web3';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import * as eth_wallet from 'ethereumjs-wallet';
import {BigNumber} from "bignumber.js";
// import ethers from 'ethers';
import contractsMeta from './contracts';
import {
    BalanceMeta,
    IContractEvent,
    IContractsAddresses,
    IEhtereumNetworks,
    IERC20,
    ILockup,
    ITwoKeyAcquisitionCampaign,
    ITwoKeyBase,
    ITwoKeyCongress,
    ITwoKeyHelpers,
    ITwoKeyInit,
    ITwoKeyUtils,
} from './interfaces';
import Index, {promisify} from './utils';
import Helpers from './utils/helpers';
import AcquisitionCampaign from './acquisition';
import ERC20 from './erc20';
import Lockup from './lockup';
import TwoKeyCongress from "./congress";

// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
    // ipfsIp: '192.168.47.100',
    // ipfsIp: 'ipfs.aydnep.com.ua',
    ipfsIp: 'ipfs.infura.io',
    ipfsPort: '5001',
    // ipfsPort: '15001',
    ipfsProtocol: 'https',
    mainNetId: 3,
    syncTwoKeyNetId: 17,
    twoKeySyncUrl: 'https://test.plasma.2key.network/',
    twoKeyMainUrl: 'http://localhost:8585'
};

export class TwoKeyProtocol {
    private web3: any;
    private plasmaWeb3: any;
    private ipfs: any;
    public gasPrice: number;
    public totalSupply: number;
    public gas: number;
    private networks: IEhtereumNetworks;
    private contracts: IContractsAddresses;
    private twoKeyEconomy: any;
    private twoKeyAdmin: any;
    private twoKeyCongress: any;
    private twoKeyReg: any;
    private twoKeyPlasmaEvents: any;
    private twoKeyCall: any;
    private twoKeyEvents: any;
    private plasmaAddress: string;
    public ERC20: IERC20;
    public Utils: ITwoKeyUtils;
    private Helpers: ITwoKeyHelpers;
    public AcquisitionCampaign: ITwoKeyAcquisitionCampaign;
    public Congress: ITwoKeyCongress;
    public Lockup: ILockup;
    private _log: any;

    // private twoKeyReg: any;

    constructor(initValues: ITwoKeyInit) {
        this.setWeb3(initValues);
    }

    public setWeb3(initValues: ITwoKeyInit) {
        // setWeb3 MainNet Client
        const {
            web3,
            rpcUrl,
            eventsNetUrl = TwoKeyDefaults.twoKeySyncUrl,
            ipfsIp = TwoKeyDefaults.ipfsIp,
            ipfsPort = TwoKeyDefaults.ipfsPort,
            ipfsProtocol: protocol = TwoKeyDefaults.ipfsProtocol,
            contracts,
            networks,
            plasmaPK,
        } = initValues;
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

        this._log = initValues.log || console.log;

        // setWeb3 2KeySyncNet Client
        const private_key = Buffer.from(plasmaPK, 'hex');
        const eventsWallet = eth_wallet.fromPrivateKey(private_key);

        const plasmaEngine = new ProviderEngine();
        const plasmaProvider = eventsNetUrl.startsWith('http') ? new RpcSubprovider({rpcUrl: eventsNetUrl}) : new WSSubprovider({rpcUrl: eventsNetUrl});
        plasmaEngine.addProvider(new WalletSubprovider(eventsWallet, {}));
        plasmaEngine.addProvider(plasmaProvider);

        plasmaEngine.start();
        this.plasmaWeb3 = new Web3(plasmaEngine);
        this.plasmaAddress = `0x${eventsWallet.getAddress().toString('hex')}`;
        this.twoKeyPlasmaEvents = this.plasmaWeb3.eth.contract(contractsMeta.TwoKeyPlasmaEvents.abi).at(contractsMeta.TwoKeyPlasmaEvents.networks[this.networks.syncTwoKeyNetId].address);

        if (web3) {
            this.web3 = new Web3(web3.currentProvider);
            this.web3.eth.defaultBlock = 'pending';
            // this.twoKeyEventSource = this.web3.eth.contract(contractsMeta.TwoKeyEventSource.abi).at(contractsMeta.TwoKeyEventSource.networks[this.networks.mainNetId].address);
        } else if (rpcUrl) {
            const mainEngine = new ProviderEngine();
            this.web3 = new Web3(mainEngine);
            const mainProvider = rpcUrl.startsWith('http') ? new RpcSubprovider({rpcUrl}) : new WSSubprovider({rpcUrl});
            // mainEngine.addProvider(new WalletSubprovider(eventsWallet, {}));
            mainEngine.addProvider(mainProvider);
            mainEngine.start();
        } else {
            throw new Error('No web3 instance');
        }
        this.twoKeyEconomy = this.web3.eth.contract(contractsMeta.TwoKeyEconomy.abi).at(contractsMeta.TwoKeyEconomy.networks[this.networks.mainNetId].address);
        this.twoKeyReg = this.web3.eth.contract(contractsMeta.TwoKeyReg.abi).at(contractsMeta.TwoKeyReg.networks[this.networks.mainNetId].address);
        this.twoKeyAdmin = this.web3.eth.contract(contractsMeta.TwoKeyAdmin.abi).at(contractsMeta.TwoKeyAdmin.networks[this.networks.mainNetId].address);
        this.twoKeyCongress = this.web3.eth.contract(contractsMeta.TwoKeyCongress.abi).at(contractsMeta.TwoKeyCongress.networks[this.networks.mainNetId].address);
        this.twoKeyCall = this.web3.eth.contract(contractsMeta.Call.abi).at(contractsMeta.Call.networks[this.networks.mainNetId].address);

        this.ipfs = ipfsAPI(ipfsIp, ipfsPort, {protocol});

        const twoKeyBase: ITwoKeyBase = {
            web3: this.web3,
            plasmaWeb3: this.plasmaWeb3,
            ipfs: this.ipfs,
            networks: this.networks,
            contracts: this.contracts,
            twoKeyEconomy: this.twoKeyEconomy,
            twoKeyReg: this.twoKeyReg,
            twoKeyCongress: this.twoKeyCongress,
            twoKeyPlasmaEvents: this.twoKeyPlasmaEvents,
            twoKeyCall: this.twoKeyCall,
            plasmaAddress: this.plasmaAddress,
            _getGasPrice: this._getGasPrice,
            _setGasPrice: this._setGasPrice,
            _setTotalSupply: this._setTotalSupply,
            _log: this._log,
        };

        this.Helpers = new Helpers(twoKeyBase);
        this.ERC20 = new ERC20(twoKeyBase, this.Helpers);
        this.Utils = new Index(twoKeyBase, this.Helpers);
        this.AcquisitionCampaign = new AcquisitionCampaign(twoKeyBase, this.Helpers, this.Utils, this.ERC20);
        this.Congress = new TwoKeyCongress(twoKeyBase, this.Helpers, this.Utils);
        this.Lockup = new Lockup(twoKeyBase, this.Helpers, this.AcquisitionCampaign);
    }

    public getBalance(address: string, erc20address?: string): Promise<BalanceMeta> {
        const promises = [
            this.Helpers._getEthBalance(address),
            this.Helpers._getTokenBalance(address, erc20address),
            this.Helpers._getTotalSupply(erc20address),
            this.Helpers._getGasPrice()
        ];
        return new Promise(async (resolve, reject) => {
            try {
                const [eth, token, total, gasPrice] = await Promise.all(promises);
                resolve({
                    balance: {
                        ETH: eth,
                        '2KEY': token,
                        total
                    },
                    local_address: address,
                    gasPrice,
                });
            } catch (e) {
                reject(e);
            }
        });
    }

    public subscribe2KeyEvents(callback: (error: any, event: IContractEvent) => void) {
        this.twoKeyEvents = this.twoKeyPlasmaEvents.allEvents({fromBlock: 0, toBlock: 'pending'});
        this.twoKeyEvents.watch(callback);
    }

    public unsubscribe2KeyEvents() {
        if (this.twoKeyEvents && this.twoKeyEvents.stopWatching) {
            this.twoKeyEvents.stopWatching();
        }
    }

    public getContractorCampaigns(from: string): Promise<string[]> {
        return new Promise<string[]>(async (resolve, reject) => {
            try {
                const campaigns = await promisify(this.twoKeyReg.getContractsWhereUserIsContractor, [from, {from}]);
                resolve(campaigns);
            } catch (e) {
                reject(e);
            }
        });
    }

    /* TRANSFERS */

    public getERC20TransferGas(to: string, value: number | string | BigNumber, from: string): Promise<number> {
        this.gas = null;
        return new Promise(async (resolve, reject) => {
            try {
                this.gas = await promisify(this.twoKeyEconomy.transfer.estimateGas, [to, value, {from}]);
                resolve(this.gas);
            } catch (e) {
                reject(e);
            }
        });
    }

    public getETHTransferGas(to: string, value: number | string | BigNumber, from: string): Promise<number> {
        this.gas = null;
        return new Promise(async (resolve, reject) => {
            try {
                this.gas = await promisify(this.web3.eth.estimateGas, [{to, value, from}]);
                resolve(this.gas);
            } catch (e) {
                reject(e);
            }
        });
    }

    public transfer2KEYTokens(to: string, value: number | string | BigNumber, from: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const nonce = await this.Helpers._getNonce(from);
                const params = {from, gasPrice, nonce};
                const txHash = await promisify(this.twoKeyEconomy.transfer, [to, value, params]);
                resolve(txHash);
            } catch (err) {
                reject(err);
            }
        })
    }

    public transferEther(to: string, value: number | string | BigNumber, from: string, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const nonce = await this.Helpers._getNonce(from);
                const params = {to, gasPrice, value, from, nonce};
                const txHash = await promisify(this.web3.eth.sendTransaction, [params]);
                resolve(txHash);
            } catch (err) {
                reject(err);
            }
        });
    }

    /* PRIVATE HELPERS */

    private _getGasPrice() {
        return this.gasPrice;
    }

    private _setGasPrice(gasPrice: number) {
        this.gasPrice = gasPrice;
    }

    private _setTotalSupply(totalSupply: number) {
        this.totalSupply = totalSupply;
    }
}
