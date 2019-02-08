import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import singletons from '../src/contracts/singletons';
import createWeb3 from './_web3';
import Sign from '../src/sign';

const { env } = process;
const rpcUrl = env.RPC_URL;
const mainNetId = parseInt(env.MAIN_NET_ID, 10);
const syncTwoKeyNetId = env.SYNC_NET_ID;
const destinationAddress = env.AYDNEP_ADDRESS;
console.log(mainNetId);

// const twoKeyEconomy = contractsMeta.TwoKeyEconomy.networks[mainNetId].address;

const gasPrice = process.env.GASPRICE || 5000000000;
console.log(rpcUrl);
console.log(mainNetId);
console.log(singletons.TwoKeyEventSource.networks[mainNetId].address);
console.log(singletons.TwoKeyEconomy.networks[mainNetId].address);

const sendTokens: any = new Promise(async (resolve, reject) => {
    try {
        // const { web3, address } = createWeb3('laundry version question endless august scatter desert crew memory toy attract cruel', rpcUrl);
        const { web3, address } = createWeb3('laundry version question endless august scatter desert crew memory toy attract cruel', rpcUrl)
        const twoKeyProtocol = new TwoKeyProtocol({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey(),
        });
        const {balance} = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(destinationAddress), {inWei: true});
        if (parseFloat(balance['2KEY'].toString()) <= 20000 || process.env.FORCE) {
            console.log('NO BALANCE at aydnep account');
            twoKeyProtocol.twoKeyAdmin.transfer2KeyTokens(destinationAddress, twoKeyProtocol.Utils.toWei(1000000, 'ether'), { from: address, gas: 7000000, gasPrice },  async (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    console.log('Send Tokens', res);
                    const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(res);
                    resolve(receipt);
                }
            });
        } else {
            resolve(balance['2KEY']);
        }
    } catch (err) {
        reject(err);
    }
});

describe('TwoKeyProtocol dev-local', () => {
    it('dev-local: should transfer tokens', async () => {
        const receipt = await sendTokens;
        console.log(receipt);
        expect(receipt.status).to.be.equal('0x1');
    }).timeout(600000);
});
