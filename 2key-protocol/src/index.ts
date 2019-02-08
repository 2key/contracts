import ipfsAPI from 'ipfs-http-client';
import Web3 from 'web3';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import NonceSubprovider from 'web3-provider-engine/subproviders/nonce-tracker';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import * as eth_wallet from 'ethereumjs-wallet';
import {BigNumber} from "bignumber.js";
// import ethers from 'ethers';
import singletons from './contracts/singletons';
import {
    BalanceMeta,
    IContractEvent,
    IContractsAddresses,
    IDecentralizedNation,
    IEhtereumNetworks,
    IERC20,
    ITwoKeyAcquisitionCampaign,
    ITwoKeyBase,
    ITwoKeyCongress,
    ITwoKeyExchangeContract,
    ITwoKeyHelpers,
    ITwoKeyInit,
    ITwoKeyReg,
    ITwoKeyUtils,
    IUpgradableExchange
} from './interfaces';
import { promisify } from './utils/promisify';
import Index from './utils';
import Helpers from './utils/helpers';
import AcquisitionCampaign from './acquisition';
import ERC20 from './erc20';
import TwoKeyCongress from "./congress";
import DecentralizedNation from "./decentralizedNation";
import TwoKerRegistry from './registry';
import PlasmaEvents from './plasma';
import UpgradableExchange from './upgradableExchange';
import TwoKeyExchangeContract from './exchangeETHUSD';
import {IPlasmaEvents} from './plasma/interfaces';
import Sign from './sign';
// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
    ipfsRIp: 'ipfs.io',
    ipfsRPort: '443',
    ipfsRProtocol: 'https',
    ipfsWIp: 'ipfs.infura.io',
    ipfsWPort: '5001',
    ipfsWProtocol: 'https',
    mainNetId: 3,
    syncTwoKeyNetId: 98052,
    // twoKeySyncUrl: 'https://test.plasma.2key.network/',
    twoKeySyncUrl: 'https://rpc.private.test.k8s.2key.net',
    twoKeyMainUrl: 'https://rpc.public.test.k8s.2key.net',
};

function getDeployedAddress(contract: string, networkId: number | string): string {
    const network = singletons[contract] && singletons[contract].networks[networkId] || {};
    return network.Proxy || network.address;
}


export class TwoKeyProtocol {
    private web3: any;
    public plasmaWeb3: any;
    private ipfsW: any;
    private ipfsR: any;
    public gasPrice: number;
    public totalSupply: number;
    public gas: number;
    private networks: IEhtereumNetworks;
    private contracts: IContractsAddresses;
    public twoKeyEventSource: any;
    private twoKeyBase: ITwoKeyBase;
    private twoKeyExchangeContract: any;
    private twoKeyUpgradableExchange: any;
    private twoKeyEconomy: any;
    private twoKeyBaseReputationRegistry: any;
    private twoKeySingletonesRegistry: any;
    public twoKeyAdmin: any;
    private twoKeyCongress: any;
    private twoKeyReg: any;
    public twoKeyPlasmaEvents: any;
    private twoKeyCall: any;
    private twoKeyEvents: any;
    public plasmaAddress: string;
    public plasmaPrivateKey: string;
    public ERC20: IERC20;
    public Utils: ITwoKeyUtils;
    private Helpers: ITwoKeyHelpers;
    public AcquisitionCampaign: ITwoKeyAcquisitionCampaign;
    public DecentralizedNation: IDecentralizedNation;
    public Congress: ITwoKeyCongress;
    public Registry: ITwoKeyReg;
    public UpgradableExchange: IUpgradableExchange;
    public TwoKeyExchangeContract: ITwoKeyExchangeContract;
    public PlasmaEvents: IPlasmaEvents;
    private AcquisitionSubmodule: any;
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
            ipfsRIp = TwoKeyDefaults.ipfsRIp,
            ipfsRPort = TwoKeyDefaults.ipfsRPort,
            ipfsRProtocol = TwoKeyDefaults.ipfsRProtocol,
            ipfsWIp = TwoKeyDefaults.ipfsWIp,
            ipfsWPort = TwoKeyDefaults.ipfsWPort,
            ipfsWProtocol = TwoKeyDefaults.ipfsWProtocol,
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
        this._log('Plasma RPC', eventsNetUrl);

        this.plasmaPrivateKey = plasmaPK;
        // setWeb3 2KeySyncNet Client
        const private_key = Buffer.from(plasmaPK, 'hex');
        const eventsWallet = eth_wallet.fromPrivateKey(private_key);

        const plasmaEngine = new ProviderEngine();
        const plasmaProvider = eventsNetUrl.startsWith('http') ? new RpcSubprovider({rpcUrl: eventsNetUrl}) : new WSSubprovider({rpcUrl: eventsNetUrl});
        plasmaEngine.addProvider(new WalletSubprovider(eventsWallet, {}));
        plasmaEngine.addProvider(new NonceSubprovider());
        plasmaEngine.addProvider(plasmaProvider);

        plasmaEngine.start();
        this.plasmaWeb3 = new Web3(plasmaEngine);
        this.plasmaAddress = `0x${eventsWallet.getAddress().toString('hex')}`;
        this.twoKeyPlasmaEvents = this.plasmaWeb3.eth.contract(singletons.TwoKeyPlasmaEvents.abi).at(getDeployedAddress('TwoKeyPlasmaEvents', this.networks.syncTwoKeyNetId));

        if (web3) {
            this.web3 = new Web3(web3.currentProvider);
            this.web3.eth.defaultBlock = 'pending';
            // this.twoKeyEventSource = this.web3.eth.contract(contractsMeta.TwoKeyEventSource.abi).at(contractsMeta.TwoKeyEventSource.networks[this.networks.mainNetId].address);
        } else if (rpcUrl) {
            const mainEngine = new ProviderEngine();
            this.web3 = new Web3(mainEngine);
            const mainProvider = rpcUrl.startsWith('http') ? new RpcSubprovider({rpcUrl}) : new WSSubprovider({rpcUrl});
            // mainEngine.addProvider(new WalletSubprovider(eventsWallet, {}));
            mainEngine.addProvider(new NonceSubprovider());
            mainEngine.addProvider(mainProvider);
            mainEngine.start();
        } else {
            throw new Error('No web3 instance');
        }

        //contractsMeta.TwoKeyRegLogic.networks[this.networks.mainNetId].address
        this.twoKeySingletonesRegistry = this.web3.eth.contract(singletons.TwoKeySingletonesRegistry.abi).at(getDeployedAddress('TwoKeySingletonesRegistry', this.networks.mainNetId))
        this.twoKeyExchangeContract = this.web3.eth.contract(singletons.TwoKeyExchangeRateContract.abi).at(getDeployedAddress('TwoKeyExchangeRateContract', this.networks.mainNetId));
        this.twoKeyUpgradableExchange = this.web3.eth.contract(singletons.TwoKeyUpgradableExchange.abi).at(getDeployedAddress('TwoKeyUpgradableExchange', this.networks.mainNetId));
        this.twoKeyEconomy = this.web3.eth.contract(singletons.TwoKeyEconomy.abi).at(getDeployedAddress('TwoKeyEconomy', this.networks.mainNetId));
        this.twoKeyReg = this.web3.eth.contract(singletons.TwoKeyRegistry.abi).at(getDeployedAddress('TwoKeyRegistry', this.networks.mainNetId));
        this.twoKeyEventSource = this.web3.eth.contract(singletons.TwoKeyEventSource.abi).at(getDeployedAddress('TwoKeyEventSource', this.networks.mainNetId));
        this.twoKeyAdmin = this.web3.eth.contract(singletons.TwoKeyAdmin.abi).at(getDeployedAddress('TwoKeyAdmin', this.networks.mainNetId));
        this.twoKeyCongress = this.web3.eth.contract(singletons.TwoKeyCongress.abi).at(getDeployedAddress('TwoKeyCongress', this.networks.mainNetId));
        this.twoKeyCall = this.web3.eth.contract(singletons.Call.abi).at(getDeployedAddress('Call', this.networks.mainNetId));
        this.twoKeyBaseReputationRegistry = this.web3.eth.contract(singletons.TwoKeyCongress.abi).at(getDeployedAddress('TwoKeyBaseReputationRegistry', this.networks.mainNetId));
        this.ipfsR = ipfsAPI(ipfsRIp, ipfsRPort, {protocol: ipfsRProtocol});
        this.ipfsW = ipfsAPI(ipfsWIp, ipfsWPort, {protocol: ipfsWProtocol});

        this.twoKeyBase = {
            web3: this.web3,
            plasmaWeb3: this.plasmaWeb3,
            ipfsR: this.ipfsR,
            ipfsW: this.ipfsW,
            networks: this.networks,
            contracts: this.contracts,
            twoKeySingletonesRegistry: this.twoKeySingletonesRegistry,
            twoKeyAdmin: this.twoKeyAdmin,
            twoKeyEventSource: this.twoKeyEventSource,
            twoKeyExchangeContract: this.twoKeyExchangeContract,
            twoKeyUpgradableExchange: this.twoKeyUpgradableExchange,
            twoKeyEconomy: this.twoKeyEconomy,
            twoKeyReg: this.twoKeyReg,
            twoKeyCongress: this.twoKeyCongress,
            twoKeyPlasmaEvents: this.twoKeyPlasmaEvents,
            twoKeyCall: this.twoKeyCall,
            twoKeyBaseReputationRegistry: this.twoKeyBaseReputationRegistry,
            plasmaAddress: this.plasmaAddress,
            plasmaPrivateKey: this.plasmaPrivateKey,
            _getGasPrice: this._getGasPrice,
            _setGasPrice: this._setGasPrice,
            _setTotalSupply: this._setTotalSupply,
            _log: this._log,
        };

        this.Helpers = new Helpers(this.twoKeyBase);
        this.ERC20 = new ERC20(this.twoKeyBase, this.Helpers);
        this.Utils = new Index(this.twoKeyBase, this.Helpers);
        this.PlasmaEvents = new PlasmaEvents(this.twoKeyBase, this.Helpers, this.Utils);
        this.TwoKeyExchangeContract = new TwoKeyExchangeContract(this.twoKeyBase, this.Helpers, this.Utils);
        this.UpgradableExchange = new UpgradableExchange(this.twoKeyBase,this.Helpers,this.Utils);
        this.Congress = new TwoKeyCongress(this.twoKeyBase, this.Helpers, this.Utils);
        this.Registry = new TwoKerRegistry(this.twoKeyBase, this.Helpers, this.Utils);
        // TODO: Add here replace AcquisitionSubmodule mechanism
        this.AcquisitionCampaign = this.AcquisitionSubmodule
            ? new this.AcquisitionSubmodule(this.twoKeyBase, this.Helpers, this.Utils, this.ERC20, Sign)
            : new AcquisitionCampaign(this.twoKeyBase, this.Helpers, this.Utils, this.ERC20, Sign);
        this.DecentralizedNation = new DecentralizedNation(this.twoKeyBase, this.Helpers, this.Utils, this.AcquisitionCampaign);
    }

    public replaceAcquisition(AcquisitionSubmodule) {
        this.AcquisitionSubmodule = AcquisitionSubmodule;
        this.AcquisitionCampaign = new AcquisitionSubmodule(this.twoKeyBase, this.Helpers, this.Utils, this.ERC20, Sign);
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
