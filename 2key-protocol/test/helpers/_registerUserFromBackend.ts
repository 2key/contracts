import bip39 from "bip39";
import * as eth_wallet from 'ethereumjs-wallet';
import hdkey from 'ethereumjs-wallet/hdkey';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import Web3 from 'web3';
import { TwoKeyProtocol } from '../../src';
import { ISignedPlasma, ISignedWalletData } from '../../src/registry/interfaces';
import { ISignedEthereum, ISignedUsername } from '../../src/plasma/interfaces';



export interface IRegistryData {
    signature?: string,
    plasmaAddress?: string,
    ethereumAddress?: string,
    username?: string
}

async function registerUserFromBackend({ signature, plasmaAddress, ethereumAddress, username }: IRegistryData) {
    const deployerMnemonic = process.env.MNEMONIC_AYDNEP;
    const eventsNetUrls = [process.env.PLASMA_RPC_URL];
    const deployerPK = process.env.MNEMONIC_AYDNEP ? null : '9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec';
    const networkId = parseInt(process.env.MAIN_NET_ID, 10);
    const privateNetworkId = parseInt(process.env.SYNC_NET_ID, 10);

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
        eventsNetUrls,
        plasmaPK: '9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec',
        networkId,
        privateNetworkId,
    });

    const receipts = [];

    try {
        const txHash = await twoKeyProtocol.Registry.addNameByMaintainer(username, ethereumAddress, address);
        let receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log('Gas used for addName: ', receipt.gasUsed);
        receipts.push(receipt);
    } catch (e) {
        console.log('Error in adding name by maintainer', e);
        return Promise.reject(e);
    }

    try {
        const txHash = await twoKeyProtocol.Registry.addPlasma2EthereumByMaintainer(signature, plasmaAddress, ethereumAddress, address);
        let receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log('Gas used for addPlasma2Ethereum', receipt.gasUsed);
        receipts.push(receipt);
    } catch (e) {
        console.log('Error in setting plasma to ethereum by maintainer public chain', e);
        return Promise.reject(e);
    }

    try {
        const txHash = await twoKeyProtocol.PlasmaEvents.setPlasma2EthereumByMaintainer(signature, plasmaAddress, ethereumAddress);
        receipts.push(await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash, {web3: twoKeyProtocol.plasmaWeb3}));
    } catch (e) {
        console.log('Error in setting plasma to ethereum by maintainer on plasma chain',e);
        return Promise.reject(e);
    }

    try {
        const txHash = await twoKeyProtocol.PlasmaEvents.setUsernameToPlasmaOnPlasma(plasmaAddress, username);
        receipts.push(await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash, {web3: twoKeyProtocol.plasmaWeb3}));
    } catch (e) {
        console.log('Error in setting username to plasma on plasma registry', e);
        return Promise.reject(e);
    }

    return receipts;
}


if (process.argv[2] && process.argv[2].startsWith('{')) {
    console.log(process.argv[2]);
    const data = JSON.parse(process.argv[2]);
    registerUserFromBackend(data).then(() => {
        console.log('done');
        process.exit(0);
    })
}

export default registerUserFromBackend;
