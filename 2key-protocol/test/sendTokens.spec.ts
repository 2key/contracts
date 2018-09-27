import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol, promisify} from '../src';
import contractsMeta from '../src/contracts';
import createWeb3 from './_web3';

const rpcUrl = 'wss://ropsten.infura.io/ws';
const mainNetId = 3;
const syncTwoKeyNetId = 47;
const destinationAddress = '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';
console.log(mainNetId);

const twoKeyEconomy = contractsMeta.TwoKeyEconomy.networks[mainNetId].address;


console.log(rpcUrl);
console.log(mainNetId);
console.log(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
console.log(contractsMeta.TwoKeyEconomy.networks[mainNetId].address);

const sendTokens: any = new Promise(async (resolve, reject) => {
    try {
        const { web3, address } = createWeb3('laundry version question endless august scatter desert crew memory toy attract cruel', rpcUrl);
        const twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        const {balance} = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(destinationAddress), true);
        if (parseFloat(balance['2KEY'].toString()) <= 20000) {
            console.log('NO BALANCE at aydnep account');
            const admin = web3.eth.contract(contractsMeta.TwoKeyAdmin.abi).at(contractsMeta.TwoKeyAdmin.networks[mainNetId].address);
            admin.transfer2KeyTokens(twoKeyEconomy, destinationAddress, twoKeyProtocol.toWei(100000, 'ether'), { from: address, gas: 7000000, gasPrice: 5000000000 },  async (err, res) => {
                if (err) {
                    reject(err);
                } else {
                    console.log('Send Tokens', res);
                    const receipt = await twoKeyProtocol.getTransactionReceiptMined(res);
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

describe('TwoKeyProtocol ROPSTEN', () => {
    it('ROPSTEN: should transfer tokens', async () => {
        const receipt = await sendTokens;
        expect(receipt.status).to.be.equal('0x1');
    }).timeout(600000);
});
