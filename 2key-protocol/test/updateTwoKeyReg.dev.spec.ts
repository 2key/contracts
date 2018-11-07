import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import contractsMeta from '../src/contracts';
import web3switcher from './_web3';
import Sign from '../src/utils/sign';

const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
console.log(mainNetId);

const network = process.env.RINKEBY ? 'RINKEBY' : 'ROPSTEN';
// const gasPrice = process.env.GASPRICE || 5000000000;
console.log(rpcUrl);
console.log(mainNetId);
console.log(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
console.log(contractsMeta.TwoKeyEconomy.networks[mainNetId].address);

describe(`TwoKeyProtocol ${network}`, () => {
    it('should populate data', async() => {
        const { web3, address } = await web3switcher(rpcUrl, rpcUrl, '9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec');
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
            '0x22d491bde2303f2f43325b2108d26f1eaba1e32b'
        ];

        let initialUsernames = [
            'Nikola',
            'Andrii',
            'Kiki'
        ];

        let initialFullNames = [
            'Nikola Madjarevic',
            'Andrii Pindiura',
            'Erez Ben Kiki'
        ];

        let initialEmails = [
            'nikola@2key.co',
            'andrii@2key.co',
            'kiki@2key.co'
        ];
        let hash = await twoKeyProtocol.DecentralizedNation.populateData(initialUsernames[0],initialAddresses[0],initialFullNames[0],initialEmails[0], from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
        let hash1 = await twoKeyProtocol.DecentralizedNation.populateData(initialUsernames[1],initialAddresses[1],initialFullNames[1],initialEmails[1], from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(hash1);
        let hash2 = await twoKeyProtocol.DecentralizedNation.populateData(initialUsernames[2],initialAddresses[2],initialFullNames[2],initialEmails[2], from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(hash2);
    }).timeout(300000);
});
