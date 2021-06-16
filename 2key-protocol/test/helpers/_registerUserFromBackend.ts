import {TwoKeyProtocol} from "../../src";
import createWeb3 from './_web3';
import {expectEqualNumbers} from "./numberHelpers";


export interface IRegistryData {
    signature?: string,
    plasmaAddress?: string,
    ethereumAddress?: string,
    username?: string
}

async function registerUserFromBackend({ signature, plasmaAddress, ethereumAddress, username }: IRegistryData) {
    const deployerMnemonic = process.env.MNEMONIC_AYDNEP;
    const eventsNetUrls = [process.env.PLASMA_RPC_URL];
    const networkId = parseInt(process.env.MAIN_NET_ID, 10);
    const privateNetworkId = parseInt(process.env.SYNC_NET_ID, 10);

    const rpcUrl = [process.env.RPC_URL];
    const { web3, plasmaWeb3, plasmaAddress: maintainerPlasmaAddress, address } = createWeb3(deployerMnemonic, rpcUrl, eventsNetUrls)
    const twoKeyProtocol = new TwoKeyProtocol({
        web3,
        plasmaWeb3,
        plasmaAddress: maintainerPlasmaAddress,
        networkId,
        privateNetworkId,
    });

    const receipts = [];

    try {
        const txHash = await twoKeyProtocol.Registry.batchRegistrationByMaintainer(signature, username, ethereumAddress, plasmaAddress,address);
        let receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log('Gas used for batched registration (addName + addPlasma2Ethereum) : ', receipt.gasUsed);
        receipts.push(receipt);
    } catch (e) {
        console.log('Error in adding name by maintainer', e);
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
        let signupReputationScore = await twoKeyProtocol.BaseReputation.getUserSignupScore(plasmaAddress);
        console.log('Signup score', signupReputationScore);
        expectEqualNumbers(5, signupReputationScore,'Signup reputation score is not good');
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
