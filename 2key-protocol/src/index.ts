import ipfsAPI from 'ipfs-api';
import {BigNumber} from 'bignumber.js';
import Web3 from 'web3';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import * as eth_wallet from 'ethereumjs-wallet';
// import ethers from 'ethers';
import contractsMeta from './contracts';
import {
    IEhtereumNetworks,
    IContractsAddresses,
    ITwoKeyInit,
    BalanceMeta,
    IContractEvent,
    ITwoKeyHelpers,
    ITWoKeyUtils, ITwoKeyBase, ITwoKeyAcquisitionCampaign, IERC20,
} from './interfaces';
import Sign from './utils/sign';
import Index, {promisify} from './utils';
import Helpers from './utils/helpers';
import AcquisitionCampaign from './acquisition';
import ERC20 from './erc20';

// const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const TwoKeyDefaults = {
    // ipfsIp: '192.168.47.100',
    ipfsIp: '37.57.185.107',
    ipfsPort: '5001',
    mainNetId: 3,
    syncTwoKeyNetId: 17,
    twoKeySyncUrl: 'http://astring.aydnep.com.ua:18545'
};

export class TwoKeyProtocol {
    private readonly web3: any;
    private readonly plasmaWeb3: any;
    private readonly ipfs: any;
    public readonly address: string;
    public gasPrice: number;
    public totalSupply: number;
    public gas: number;
    private readonly networks: IEhtereumNetworks;
    private readonly contracts: IContractsAddresses;
    private readonly twoKeyEconomy: any;
    private readonly twoKeyEventContract: any;
    private twoKeyEvents: any;
    private readonly plasmaAddress: string;
    public readonly  ERC20: IERC20;
    public readonly Utils: ITWoKeyUtils;
    private readonly Helpers: ITwoKeyHelpers;
    public readonly AcquisitionCampaign: ITwoKeyAcquisitionCampaign;

    // private twoKeyReg: any;

    constructor(initValues: ITwoKeyInit) {
        // init MainNet Client
        const {
            web3,
            address,
            eventsNetUrl = TwoKeyDefaults.twoKeySyncUrl,
            ipfsIp = TwoKeyDefaults.ipfsIp,
            ipfsPort = TwoKeyDefaults.ipfsPort,
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

        // init 2KeySyncNet Client
        const private_key = Buffer.from(plasmaPK, 'hex');
        const eventsWallet = eth_wallet.fromPrivateKey(private_key);

        const plasmaEngine = new ProviderEngine();
        const plasmaProvider = eventsNetUrl.startsWith('http') ? new RpcSubprovider({rpcUrl: eventsNetUrl}) : new WSSubprovider({rpcUrl: eventsNetUrl});
        plasmaEngine.addProvider(new WalletSubprovider(eventsWallet, {}));
        plasmaEngine.addProvider(plasmaProvider);

        plasmaEngine.start();
        this.plasmaWeb3 = new Web3(plasmaEngine);
        this.plasmaAddress = `0x${eventsWallet.getAddress().toString('hex')}`;
        this.twoKeyEventContract = this.plasmaWeb3.eth.contract(contractsMeta.TwoKeyPlasmaEvents.abi).at(contractsMeta.TwoKeyPlasmaEvents.networks[this.networks.syncTwoKeyNetId].address);

        if (web3) {
            this.web3 = new Web3(web3.currentProvider);
            this.web3.eth.defaultBlock = 'pending';
            this.address = address;
            this.twoKeyEconomy = this.web3.eth.contract(contractsMeta.TwoKeyEconomy.abi).at(contractsMeta.TwoKeyEconomy.networks[this.networks.mainNetId].address);
        }

        this.ipfs = ipfsAPI(ipfsIp, ipfsPort, {protocol: 'http'});

        const twoKeyBase: ITwoKeyBase = {
            web3: this.web3,
            plasmaWeb3: this.plasmaWeb3,
            ipfs: this.ipfs,
            address: this.address,
            networks: this.networks,
            contracts: this.contracts,
            twoKeyEconomy: this.twoKeyEconomy,
            twoKeyEventContract: this.twoKeyEventContract,
            plasmaAddress: this.plasmaAddress,
            _getGasPrice: this._getGasPrice,
            _setGasPrice: this._setGasPrice,
            _setTotalSupply: this._setTotalSupply,
        };

        this.Helpers = new Helpers(twoKeyBase);
        this.ERC20 = new ERC20(twoKeyBase, this.Helpers);
        this.Utils = new Index(twoKeyBase, this.Helpers);
        this.AcquisitionCampaign = new AcquisitionCampaign(twoKeyBase, this.Helpers, this.Utils);
    }

    public getBalance(address: string = this.address, erc20address?: string): Promise<BalanceMeta> {
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
                    local_address: this.address,
                    gasPrice,
                });
            } catch (e) {
                reject(e);
            }
        });
    }

    public subscribe2KeyEvents(callback: (error: any, event: IContractEvent) => void) {
        this.twoKeyEvents = this.twoKeyEventContract.allEvents({fromBlock: 0, toBlock: 'pending'});
        this.twoKeyEvents.watch(callback);
    }

    public unsubscribe2KeyEvents() {
        this.twoKeyEvents.stopWatching();
    }

    /* TRANSFERS */

    public getERC20TransferGas(to: string, value: number | string | BigNumber): Promise<number> {
        this.gas = null;
        return new Promise(async (resolve, reject) => {
            try {
                this.gas = await promisify(this.twoKeyEconomy.transfer.estimateGas, [to, value, {from: this.address}]);
                resolve(this.gas);
            } catch (e) {
                reject(e);
            }
        });
    }

    public getETHTransferGas(to: string, value: number | string | BigNumber): Promise<number> {
        this.gas = null;
        return new Promise(async (resolve, reject) => {
            try {
                this.gas = await promisify(this.web3.eth.estimateGas, [{to, value, from: this.address}]);
                resolve(this.gas);
            } catch (e) {
                reject(e);
            }
        });
    }

    public transfer2KEYTokens(to: string, value: number | string | BigNumber, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise<string>(async (resolve, reject) => {
            try {
                const params = {from: this.address, gasPrice};
                const txHash = await promisify(this.twoKeyEconomy.transfer, [to, value, params]);
                resolve(txHash);
            } catch (err) {
                reject(err);
            }
        })
    }

    public transferEther(to: string, value: number | string | BigNumber, gasPrice: number = this.gasPrice): Promise<string> {
        return new Promise(async (resolve, reject) => {
            try {
                const params = {to, gasPrice, value, from: this.address};
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
