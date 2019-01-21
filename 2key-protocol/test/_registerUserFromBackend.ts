import bip39 from "bip39";
import * as eth_wallet from 'ethereumjs-wallet';
import hdkey from 'ethereumjs-wallet/hdkey';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import Web3 from 'web3';
import Sign from '../src/utils/sign';
import { TwoKeyProtocol } from '../src';
import { ISignedPlasma } from '../src/registry/interfaces';


interface IUser {
    address: string,
    name: string,
    email: string,
    fullname: string,
}

export interface IRegistryData {
    user?: IUser,
    signedPlasma?: ISignedPlasma,
    plasma2EthereumSignature?: string,
    plasmaAddress?: string,
}

async function registerUserFromBackend({ user, signedPlasma, plasma2EthereumSignature, plasmaAddress }: IRegistryData = {}) {
    console.log('registerUserFromBackend', user, signedPlasma, plasma2EthereumSignature);
    if (!user && ! signedPlasma && !plasma2EthereumSignature) {
        console.log('Nothing todo!');
        return Promise.resolve(true);
    }
    const mainNetId = process.env.MAIN_NET_ID;
    const syncTwoKeyNetId = process.env.SYNC_NET_ID;
    const deployerMnemonic = process.env.MNEMONIC_AYDNEP;
    const deployerPK = process.env.MNEMONIC_AYDNEP ? null : '9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec';

    const rpcUrl = process.env.RPC_URL;
    let wallet;
    if (deployerPK) {
        const private_key = Buffer.from(deployerPK, 'hex');
        wallet = eth_wallet.fromPrivateKey(private_key);
    } else {
        const hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(deployerMnemonic));
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
    const twoKeyProtocol = new TwoKeyProtocol({
        web3,
        networks: {
            mainNetId,
            syncTwoKeyNetId,
        },
        plasmaPK: Sign.generatePrivateKey(),
    });
    console.log('registerUserFromBackend.plasmaAddress', twoKeyProtocol.plasmaAddress);
    const txHashes = [];
    if (user) {
        txHashes.push(twoKeyProtocol.Utils.getTransactionReceiptMined(await twoKeyProtocol.Registry.addName(user.name, user.address, user.email, user.email, address)));
    }
    if (signedPlasma) {
        txHashes.push(twoKeyProtocol.Utils.getTransactionReceiptMined(await twoKeyProtocol.Registry.addPlasma2EthereumByUser(address, signedPlasma)));
    }
    if (plasma2EthereumSignature) {
        txHashes.push(twoKeyProtocol.Utils.getTransactionReceiptMined(await  twoKeyProtocol.PlasmaEvents.setPlasmaToEthereumOnPlasma(plasmaAddress, plasma2EthereumSignature), { web3: twoKeyProtocol.plasmaWeb3 }));
    }
    return Promise.all(txHashes);
}

export default registerUserFromBackend;