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
import { ISignedPlasma, ISignedWalletData } from '../src/registry/interfaces';
import { ISignedEthereum } from '../src/plasma/interfaces';
import {promisify} from "../src/utils";


interface IUser {
    name: string,
    address: string,
    fullname: string,
    email: string,
    signature: string,
}

/*
export interface ISignedPlasma {
    encryptedPlasmaPrivateKey: string,
    ethereum2plasmaSignature: string,
    externalSignature: string
}
*/

export interface IRegistryData {
    signedUser?: IUser,
    signedPlasma?: ISignedPlasma,
    signedEthereum?: ISignedEthereum,
    signedWallet?: ISignedWalletData,
}

async function registerUserFromBackend({ signedUser, signedPlasma, signedEthereum, signedWallet }: IRegistryData = {}) {
    // console.log('registerUserFromBackend', signedUser, signedPlasma, signedEthereum, signedWallet);
    console.log('\r\n');
    if (!signedUser && ! signedPlasma && !signedEthereum) {
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
        plasmaPK: '9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec',
    });
    console.log('PlasmaEvents:', twoKeyProtocol.twoKeyPlasmaEvents.address);
    console.log('registerUserFromBackend.plasmaAddress', twoKeyProtocol.plasmaAddress);
    console.log('\r\n');
    const txHashes = [];
    try {
        if (signedUser && signedWallet) {
            const txHash = await twoKeyProtocol.Registry.addNameAndWalletName(address, signedUser.name, signedUser.address, signedUser.fullname, signedUser.email, signedWallet.walletname, signedUser.signature, signedWallet.signature);
            console.log('Registry.addNameAndWalletName hash', txHash);
            console.log('\r\n');
            txHashes.push(twoKeyProtocol.Utils.getTransactionReceiptMined(txHash));
        } else {
            try {
                if (signedUser) {
                    const txHash = await twoKeyProtocol.Registry.addName(signedUser.name, signedUser.address, signedUser.fullname, signedUser.email, signedUser.signature, address);
                    console.log('Registry.addName hash', txHash);
                    console.log('\r\n');
                    txHashes.push(twoKeyProtocol.Utils.getTransactionReceiptMined(txHash));
                }
            } catch (e) {
                console.log('Error in Registry.addName');
                throw e;
            }
            if (signedWallet) {
                try {
                    const txHash = await twoKeyProtocol.Registry.setWalletName(address, signedWallet);
                    console.log('Registry.setWalletName hash', txHash);
                    console.log('\r\n');
                    txHashes.push(twoKeyProtocol.Utils.getTransactionReceiptMined(txHash));
                } catch (e) {
                    console.log('Error in Registry.setWalletName');
                    throw e;
                }
            }
        }
    } catch (e) {
        console.log('Error in user/wallet', e);
        return Promise.reject(e);
    }
    if (signedPlasma) {
        try {
            const txHash = await twoKeyProtocol.Registry.addPlasma2EthereumByUser(address, signedPlasma);
            console.log('Registry.addPlasma2EthereumByUser hash', txHash);
            console.log('\r\n');
            txHashes.push(twoKeyProtocol.Utils.getTransactionReceiptMined(txHash));
        } catch (e) {
            console.log('Error in Registry.addPlasma2EthereumByUser');
            return Promise.reject(e);
        }
    }
    if (signedEthereum) {
        try {
            const txHash = await twoKeyProtocol.PlasmaEvents.setPlasmaToEthereumOnPlasma(signedEthereum.plasmaAddress, signedEthereum.plasma2ethereumSignature);
            console.log('PlasmaEvents.setPlasmaToEthereumOnPlasma hash', txHash);
            console.log('\r\n');
            txHashes.push(twoKeyProtocol.Utils.getTransactionReceiptMined(txHash, {web3: twoKeyProtocol.plasmaWeb3}));
        } catch (e) {
            console.log('Error in PlasmaEvents.setPlasmaToEthereumOnPlasma');
            return Promise.reject(e);
        }
    }
    return Promise.all(txHashes);
}

console.log(process.argv[2].startsWith('{'));
if (process.argv[2] && process.argv[2].startsWith('{')) {
    console.log(process.argv[2]);
    const data = JSON.parse(process.argv[2]);
    registerUserFromBackend(data).then(() => {
        console.log('done');
        process.exit(0);
    })
}

export default registerUserFromBackend;