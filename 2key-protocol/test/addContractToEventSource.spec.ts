import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import contractsMeta from '../src/contracts';
import createWeb3, { ledgerWeb3 } from './_web3';
import Sign from '../src/utils/sign';
import { promisify } from '../src/utils';



//  RINKEBY=true yarn run test:one 2key-protocol/test/updateTwoKeyReg.spec.ts "0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7:2key13:Andrii Pindiura:aydnep@aydnep.com.ua"


const rpcUrl = process.env.RINKEBY ? 'https://rpc.public.test.k8s.2key.net' : 'wss://ropsten.infura.io/ws';
// const rpcUrl = 'wss://ropsten.infura.io/ws';
const mainNetId = process.env.RINKEBY ? 4 : 3;
const syncTwoKeyNetId = 98052;
console.log(mainNetId);

const network = process.env.RINKEBY ? 'RINKEBY' : 'ROPSTEN';
const gasPrice = process.env.GASPRICE || 5000000000;
console.log(rpcUrl);
console.log(mainNetId);
console.log(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
console.log(contractsMeta.TwoKeyEconomy.networks[mainNetId].address);
console.log(process.argv);

describe(`TwoKeyProtocol ${network}`, () => {
    it('should populate data', async() => {
        const { web3, address } = process.env.HD
            ? createWeb3('laundry version question endless august scatter desert crew memory toy attract cruel', rpcUrl)
            : await ledgerWeb3(rpcUrl, mainNetId);
        const twoKeyProtocol = new TwoKeyProtocol({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const from = address;
        const txHash = await promisify(twoKeyProtocol.twoKeyEventSource.addContract, [process.argv[7], { from }])
        console.log('txHash', txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(300000);
});
