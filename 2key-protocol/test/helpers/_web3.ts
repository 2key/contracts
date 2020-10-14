import 'regenerator-runtime/runtime';
import 'babel-register';
import Web3 from 'web3';
import { mnemonicToSeed, generateMnemonic } from 'bip39';
import * as eth_wallet from 'ethereumjs-wallet';
import hdkey from 'ethereumjs-wallet/hdkey';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import NonceSubprovider from 'web3-provider-engine/subproviders/nonce-tracker';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import TransportNodeJs from '@ledgerhq/hw-transport-node-hid';
import ProviderSubprovider from 'web3-provider-engine/subproviders/provider.js';
import FiltersSubprovider from 'web3-provider-engine/subproviders/filters.js';
import createLedgerSubprovider from '@ledgerhq/web3-subprovider';


interface EthereumWeb3 {
    web3: any;
    plasmaWeb3: any;
    address: string;
    plasmaAddress: string;
    mnemonic?: string;
    privateKey?: string;
}

interface LedgerWeb3 {
    web3: any;
    address: string;
}

export function ledgerWeb3(rpcUrl: string, networkId?: number, path?: string): Promise<LedgerWeb3> {
    return new Promise<LedgerWeb3>(async (resolve, reject) => {
        try {
            const options: any = {};
            if (networkId) {
                options.networkId = networkId;
            }
            if (path) {
                options.path = path;
            }
            const getTransport = async () => TransportNodeJs.create();
            console.log(options);
            const ledger = createLedgerSubprovider(getTransport, options);
            let engine = new ProviderEngine();
            engine.addProvider(ledger);
            engine.addProvider(new FiltersSubprovider());
            engine.addProvider(new NonceSubprovider());
            const mainProvider = rpcUrl.startsWith('http') ? new RpcSubprovider({rpcUrl}) : new WSSubprovider({rpcUrl});
            engine.addProvider(mainProvider);
            engine.start();

            const web3 = new Web3(engine);
            web3.eth.getAccounts((err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve({ web3, address: res[0] });
                }
            })
        } catch (e) {
            reject(e);
        }
    });
}

/**
 *
 * @param mnemonic
 * @returns {{address: string; privateKey: string}}
 */
export const generatePlasmaFromMnemonic = (mnemonic) => {
    // const plasmaMnemonic = mnemonic.split(' ').reverse().join(' ');
    const hdwallet = hdkey.fromMasterSeed(mnemonicToSeed(mnemonic));
    const wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();
    const address = `0x${wallet.getAddress().toString('hex')}`;
    const privateKey = wallet.getPrivateKey().toString('hex');
    return {
        address,privateKey
    };
};

export const generateWalletFromMnemonic = (mnemonic) => {
    const hdwallet = hdkey.fromMasterSeed(mnemonicToSeed(mnemonic));
    const wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();
    const address = `0x${wallet.getAddress().toString('hex')}`;
    const privateKey = wallet.getPrivateKey().toString('hex');
    return {
        address,privateKey
    };
};

export default function createWeb3(mnemonicInput: string, rpcUrls: string[], eventsUrls: string[], pk?: string): EthereumWeb3 {
    let wallet;
    const mnemonic = mnemonicInput || generateMnemonic();

    if (pk) {
        const private_key = Buffer.from(pk, 'hex');
        wallet = eth_wallet.fromPrivateKey(private_key);
    } else {
        const hdwallet = hdkey.fromMasterSeed(mnemonicToSeed(mnemonic));
        wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();
    }

    const engine = new ProviderEngine();
    engine.addProvider(new WalletSubprovider(wallet, {}));
    engine.addProvider(new NonceSubprovider());
    rpcUrls.forEach(rpcUrl => {
        const mainProvider = rpcUrl.startsWith('http')
            ? new RpcSubprovider({ rpcUrl })
            : new WSSubprovider({ rpcUrl });
        engine.addProvider(mainProvider);
    });
    engine.start();
    const web3 = new Web3(engine);
    const address = `0x${wallet.getAddress().toString('hex')}`;
    const privateKey = wallet.getPrivateKey().toString('hex');

    const { address: plasmaAddress, privateKey: plasmaPK } = generatePlasmaFromMnemonic(mnemonic);
    const plasmaWallet = eth_wallet.fromPrivateKey(Buffer.from(plasmaPK, 'hex'));
    const plasmaEngine = new ProviderEngine();
    plasmaEngine.addProvider(new WalletSubprovider(plasmaWallet, {}));
    plasmaEngine.addProvider(new NonceSubprovider());
    eventsUrls.forEach(rpcUrl => {
        const mainProvider = rpcUrl.startsWith('http')
            ? new RpcSubprovider({ rpcUrl })
            : new WSSubprovider({ rpcUrl });
        plasmaEngine.addProvider(mainProvider);
    });
    plasmaEngine.start();
    const plasmaWeb3 = new Web3(plasmaEngine);


    // console.log('new Web3', address, privateKey);
    return { web3, address, privateKey, mnemonic, plasmaWeb3, plasmaAddress };
}
