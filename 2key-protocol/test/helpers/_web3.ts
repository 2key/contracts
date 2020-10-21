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
    const privateKey = pk || generateWalletFromMnemonic(mnemonic).privateKey;

    const web3 = new Web3();
    const plasmaWeb3 = new Web3();
    const account = web3.eth.accounts.privateKeyToAccount(privateKey.startsWith('0x') ? privateKey : `0x${privateKey}`);
    web3.eth.accounts.wallet.add(account);
    web3.eth.defaultAccount = account.address;
    plasmaWeb3.eth.accounts.wallet.add(account);
    plasmaWeb3.eth.defaultAccount = account.address;
    rpcUrls.forEach(rpcUrl => {
        if (rpcUrl.startsWith('http')) {
            web3.setProvider(new Web3.providers.HttpProvider(rpcUrl));
        } else {
            web3.setProvider(new Web3.providers.WebsocketProvider(rpcUrl));
        }
    });
    eventsUrls.forEach(rpcUrl => {
        if (rpcUrl.startsWith('http')) {
            plasmaWeb3.setProvider(new Web3.providers.HttpProvider(rpcUrl));
        } else {
            plasmaWeb3.setProvider(new Web3.providers.WebsocketProvider(rpcUrl));
        }
    });



    // console.log('new Web3', address, privateKey);
    return { web3, address: account.address, privateKey, mnemonic, plasmaWeb3, plasmaAddress: account.address };
}
