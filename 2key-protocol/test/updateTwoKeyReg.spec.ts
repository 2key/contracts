import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import contractsMeta from '../src/contracts';
import web3switcher from './_web3';
import Sign from '../src/utils/sign';



//  RINKEBY=true yarn run test:one 2key-protocol/test/updateTwoKeyReg.spec.ts "0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7:2key13:Andrii Pindiura:aydnep@aydnep.com.ua"


const rpcUrl = process.env.RINKEBY ? 'https://rpc.public.test.k8s.2key.net' : 'wss://ropsten.infura.io/ws';
// const rpcUrl = 'wss://ropsten.infura.io/ws';
const mainNetId = process.env.RINKEBY ? 4 : 3;
const syncTwoKeyNetId = 98052;
console.log(mainNetId);

const twoKeyEconomy = contractsMeta.TwoKeyEconomy.networks[mainNetId].address;

const network = process.env.RINKEBY ? 'RINKEBY' : 'ROPSTEN';
const gasPrice = process.env.GASPRICE || 5000000000;
console.log(rpcUrl);
console.log(mainNetId);
console.log(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
console.log(contractsMeta.TwoKeyEconomy.networks[mainNetId].address);

const [web3_address, username, name, email] = process.argv[7].split(':');

describe(`TwoKeyProtocol ${network}`, () => {
    it('should populate data', async() => {
        const { web3, address } = await web3switcher(rpcUrl, rpcUrl, 'f4318acc8a26d653570e7e600239a27a6b2307eb2f59a2b06d77bb7b9cab031f');
        const twoKeyProtocol = new TwoKeyProtocol({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });

        let initialAddresses = [
            '0xb3fa520368f2df7bed4df5185101f303f6c7decc',
            '0xffcf8fdee72ac11b5c542428b35eef5769c409f0',
            '0x22d491bde2303f2f43325b2108d26f1eaba1e32b',
            '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7'
        ];

        let initialUsernames = [
            'Nikola',
            'Andrii',
            'Kiki',
            'aydnep'
        ];

        let initialFullNames = [
            'Nikola Madjarevic',
            'Andrii Pindiura',
            'Erez Ben Kiki',
            'aydnep'
        ];

        let initialEmails = [
            'nikola@2key.co',
            'andrii@2key.co',
            'kiki@2key.co',
            'aydnep@aydnep.com.ua'
        ];
        let hash = await twoKeyProtocol.Registry.addName(username, web3_address, name, email, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
        // let hash = await twoKeyProtocol.Registry.addName(initialUsernames[0],initialAddresses[0],initialFullNames[0],initialEmails[0], from);
        // await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
        // hash = await twoKeyProtocol.Registry.addName(initialUsernames[1],initialAddresses[1],initialFullNames[1],initialEmails[1], from);
        // await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
        // hash = await twoKeyProtocol.Registry.addName(initialUsernames[2],initialAddresses[2],initialFullNames[2],initialEmails[2], from);
        // await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
        // hash = await twoKeyProtocol.Registry.addName(initialUsernames[3],initialAddresses[3],initialFullNames[3],initialEmails[3], from);
        // await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
    }).timeout(300000);
});
