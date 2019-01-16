import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import createWeb3 from './_web3';
import Sign from '../src/utils/sign';
import bip39 from 'bip39';


const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;

let twoKeyProtocol: TwoKeyProtocol;
let from: string;

const sendETH: any = (recipient) => new Promise(async (resolve, reject) => {
    try {
        console.log('Creating TwoKeyProtocol instance');
        const {web3, address} = await createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl);
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey(),
        });
        // console.log(twoKeyProtocol);
        const txHash = await twoKeyProtocol.transferEther(recipient, twoKeyProtocol.Utils.toWei(100, 'ether'), address);
        console.log(`${recipient}: ${txHash}`);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log(`Status of transfering ether: ' + ${receipt.status}`);
        resolve(receipt);
    } catch (err) {
        reject(err);
    }
});

function generateRandomHandle() {
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    for (var i = 0; i < 8; i++)
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    return text;
}

const randomMnemonic = bip39.generateMnemonic();

describe('TwoKeyProtocol LOCAL Registering user test', () => {

    it('should register a random user', async () => {
        const {address} = await createWeb3(randomMnemonic, rpcUrl);
        await sendETH(address);
        const {web3, address: randomAddress} = await createWeb3(randomMnemonic, rpcUrl);
        from = randomAddress;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey(),
        });
        let handle = generateRandomHandle();
        console.log('Random generated handle is: ' + handle);
        let txHash = await twoKeyProtocol.Registry.addNameSignedToRegistry(handle, from);

        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

        let handleFromContract = await twoKeyProtocol.Registry.checkIfUserIsRegistered(handle);
        let isRegisteredAddress = await twoKeyProtocol.Registry.checkIfAddressIsRegistered(from);
        expect(isRegisteredAddress).to.be.equal(true);
        expect(handleFromContract).to.be.equal(from);
        console.log(txHash);
    }).timeout(30000);

    it('should register user to plasma', async() => {
        let txHash = await twoKeyProtocol.PlasmaEvents.setPlasmaToEthereumOnPlasma(from);
        console.log('This is txHash : ' + txHash);
        let receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash,{web3: twoKeyProtocol.plasmaWeb3});
        console.log(receipt);
    }).timeout(30000);

});
