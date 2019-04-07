import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import createWeb3 from './_web3';
import Sign from '../src/sign';

const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;

let twoKeyProtocol: TwoKeyProtocol;
let from: string;

const sendETH: any = (recipient) => new Promise(async (resolve, reject) => {
    try {
        if (!twoKeyProtocol) {
            console.log('Creating TwoKeyProtocol instance');
            const {web3, address} = await createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl);
            from = address;
            twoKeyProtocol = new TwoKeyProtocol({
                web3,
                networks: {
                    mainNetId,
                    syncTwoKeyNetId,
                },
                plasmaPK: Sign.generatePrivateKey(),
            });
        }
        // console.log(twoKeyProtocol);
        const txHash = await twoKeyProtocol.transferEther(recipient, twoKeyProtocol.Utils.toWei(100, 'ether'), from);
        console.log(`${recipient}: ${txHash}`);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log(`Status of transfering ether: ' + ${receipt.status}`);
        resolve(receipt);
    } catch (err) {
        reject(err);
    }
});

describe('TwoKeyProtocol LOCAL', () => {
    it('LOCAL: should transfer ether', async () => {
        let error = false;
        const addresses = Object.keys(env).filter(key => key.endsWith('_ADDRESS')).map(key => env[key]);
        let l = addresses.length;
        await sendETH('0xfab160d5bdebd8139f18b521cf18e876894ea44d');
        for (let i = 1; i < l; i++) {
            const receipt = await sendETH(addresses[i]);
            if (!receipt || receipt.status !== '0x1') {
                error = true;
            }
        }
        expect(error).to.be.false;
    }).timeout(600000);
});
