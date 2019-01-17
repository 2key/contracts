import Web3 from 'web3';
import bip39 from 'bip39';
import * as eth_wallet from 'ethereumjs-wallet';
import hdkey from 'ethereumjs-wallet/hdkey';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import TransportNodeJs from '@ledgerhq/hw-transport-node-hid';
import ProviderSubprovider from 'web3-provider-engine/subproviders/provider.js';
import FiltersSubprovider from 'web3-provider-engine/subproviders/filters.js';
import createLedgerSubprovider from '@ledgerhq/web3-subprovider';


interface EthereumWeb3 {
    web3: any;
    address: string;
    privateKey?: string;
}

export function ledgerWeb3(rpcUrl: string, networkId?: number, path?: string): Promise<EthereumWeb3> {
    return new Promise<EthereumWeb3>(async (resolve, reject) => {
        try {
            const options: any = {};
            if (networkId) {
                options.networkId = networkId;
            }
            if (path) {
                options.path = path;
            }
            const getTransport = async () => {
                const transport = await TransportNodeJs.create();
                transport.setDebugMode(true);
                return transport;
            };
            console.log(options);
            const ledger = createLedgerSubprovider(getTransport, options);
            let engine = new ProviderEngine();
            engine.addProvider(ledger);
            engine.addProvider(new FiltersSubprovider());
            const mainProvider = rpcUrl.startsWith('http') ? new RpcSubprovider({rpcUrl}) : new WSSubprovider({rpcUrl});
            engine.addProvider(mainProvider);
            // engine.addProvider(new ProviderSubprovider(new Web3.providers.HttpProvider(rpcUrl)));
            // engine.addProvider(new ProviderSubprovider(rpcUrl.startsWith('http') ? new RpcSubprovider({rpcUrl}) : new WSSubprovider({rpcUrl})));
            engine.start();

            const web3 = new Web3(engine);
            web3.eth.getAccounts((err, res) => {
                if (err) {
                    reject(err);
                } else {
                    resolve({web3, address: res[0] });
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
    const plasmaMnemonic = mnemonic.split(' ').reverse().join(' ');
    const hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(plasmaMnemonic));
    const wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();
    const address = `0x${wallet.getAddress().toString('hex')}`;
    const privateKey = wallet.getPrivateKey().toString('hex');
    return {
        address,privateKey
    };
};

export default function (mnemonic: string, rpcUrl: string, pk?: string): EthereumWeb3 {
    let wallet;
    if (pk) {
        const private_key = Buffer.from(pk, 'hex');
        wallet = eth_wallet.fromPrivateKey(private_key);
    } else {
        const hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(mnemonic));
        wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();
    }

    const engine = new ProviderEngine();
    const mainProvider = rpcUrl.startsWith('http') ? new RpcSubprovider({rpcUrl}) : new WSSubprovider({rpcUrl});
    engine.addProvider(new WalletSubprovider(wallet, {}));
    engine.addProvider(mainProvider);
    engine.start();
    const web3 = new Web3(engine);
    const address = `0x${wallet.getAddress().toString('hex')}`;
    const privateKey = wallet.getPrivateKey().toString('hex');
    console.log('new Web3', address, privateKey);
    return {web3, address, privateKey};
}
