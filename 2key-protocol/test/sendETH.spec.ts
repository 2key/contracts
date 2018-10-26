import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import createWeb3 from './_web3';
import Sign from '../src/utils/sign';

const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;

let twoKeyProtocol: TwoKeyProtocol;
let from: string;

const sendETH: any = (recipient) => new Promise(async (resolve, reject) => {
    try {
        if (!twoKeyProtocol) {
            const {web3, address} = await createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl);
            from = address;
            twoKeyProtocol = new TwoKeyProtocol({
                web3,
                networks: {
                    mainNetId,
                    syncTwoKeyNetId,
                },
                plasmaPK: Sign.generatePrivateKey().toString('hex'),
            });
        }
        // console.log(twoKeyProtocol);
        const txHash = await twoKeyProtocol.transferEther({to: recipient, value: twoKeyProtocol.Utils.toWei({number: 10, unit: 'ether'}), from});
        console.log(`${recipient}: ${txHash}`);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined({txHash});
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
        for (let i = 0; i < l; i++) {
            const receipt = await sendETH(addresses[i]);
            if (!receipt || receipt.status !== '0x1') {
                error = true;
            }
        }
        expect(error).to.be.false;
    }).timeout(600000);
});
