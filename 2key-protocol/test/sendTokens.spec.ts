import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import contractsMeta from '../src/contracts';
import createWeb3, { ledgerWeb3 } from './_web3';
import Sign from '../src/utils/sign';

const rpcUrl = process.env.RINKEBY ? 'https://rpc.public.test.k8s.2key.net' : 'wss://ropsten.infura.io/ws';
// const rpcUrl = 'wss://ropsten.infura.io/ws';
const mainNetId = process.env.RINKEBY ? 4 : 3;
const syncTwoKeyNetId = 17;
const destinationAddress = '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';
console.log(mainNetId);

// const twoKeyEconomy = contractsMeta.TwoKeyEconomy.networks[mainNetId].address;

const network = process.env.RINKEBY ? 'RINKEBY' : 'ROPSTEN';
const gasPrice = process.env.GASPRICE || 5000000000;
console.log(rpcUrl);
console.log(mainNetId);
console.log(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
console.log(contractsMeta.TwoKeyEconomy.networks[mainNetId].address);

const sendTokens: any = new Promise(async (resolve, reject) => {
    try {
        // const { web3, address } = createWeb3('laundry version question endless august scatter desert crew memory toy attract cruel', rpcUrl);
        const { web3, address } = process.env.HD
            ? createWeb3('laundry version question endless august scatter desert crew memory toy attract cruel', rpcUrl)
            : await ledgerWeb3(rpcUrl, mainNetId);
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

describe(`TwoKeyProtocol ${network}`, () => {
    it(`${network}: should transfer tokens`, async () => {
        const receipt = await sendTokens;
        console.log(receipt);
        expect(receipt.status).to.be.equal('0x1');
    }).timeout(600000);
});
