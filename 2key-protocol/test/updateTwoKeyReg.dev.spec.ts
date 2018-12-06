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

// const gasPrice = process.env.GASPRICE || 5000000000;
console.log(rpcUrl);
console.log(mainNetId);
console.log(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
console.log(contractsMeta.TwoKeyEconomy.networks[mainNetId].address);

describe('TwoKeyProtocol', () => {
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
            '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7',
            '0xb3fa520368f2df7bed4df5185101f303f6c7decc',
            '0xffcf8fdee72ac11b5c542428b35eef5769c409f0',
            '0x22d491bde2303f2f43325b2108d26f1eaba1e32b',
            '0xf3c7641096bc9dc50d94c572bb455e56efc85412',
            '0xebadf86c387fe3a4378738dba140da6ce014e974',
            '0xec8b6aaee825e0bbc812ca13e1b4f4b038154688',
            '0xfc279a3c3fa62b8c840abaa082cd6b4073e699c8',
            '0xc744f2ddbca85a82be8f36c159be548022281c62',
            '0x1b00334784ee0360ddf70dfd3a2c53ccf51e5b96',
            '0x084d61962273589bf894c7b8794aa8915a06200f',

        ];

        let initialUsernames = [
            'Aydnep',
            'Nikola',
            'Andrii',
            'Kiki',
            'gmail',
            'test4',
            'renata',
            'uport',
            'gmail2',
            'aydnep2',
            'test',

        ];

        let initialFullNames = [
            'aydnep account',
            'Nikola Madjarevic',
            'Andrii Pindiura',
            'Erez Ben Kiki',
            'gmail account',
            'test4 account',
            'renata account',
            'uport account',
            'gmail2 account',
            'aydnep2 account',
            'test account',
        ];

        let initialEmails = [
            'aydneppp@gmail.com',
            'nikola@2key.co',
            'andrii@2key.co',
            'kiki@2key.co',
            'aydnep@gmail.com',
            'test4@mailinator.com',
            'renata.pindiura@gmail.com',
            'aydnep_uport@gmail.com',
            'aydnep+2@gmail.com',
            'aydnep+2@aydnep.com.ua',
            'test@gmail.com',
        ];
        const l = initialUsernames.length;
        for (let i = 0; i < l; i++) {
            const hash = await twoKeyProtocol.Registry.addName(initialUsernames[i],initialAddresses[i],initialFullNames[i],initialEmails[i], from);
            console.log(initialUsernames[i], hash);
            await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
        }
        // let hash = await twoKeyProtocol.Registry.addName(initialUsernames[0],initialAddresses[0],initialFullNames[0],initialEmails[0], from);
        // await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
        // let hash1 = await twoKeyProtocol.Registry.addName(initialUsernames[1],initialAddresses[1],initialFullNames[1],initialEmails[1], from);
        // await twoKeyProtocol.Utils.getTransactionReceiptMined(hash1);
        // let hash2 = await twoKeyProtocol.Registry.addName(initialUsernames[2],initialAddresses[2],initialFullNames[2],initialEmails[2], from);
        // await twoKeyProtocol.Utils.getTransactionReceiptMined(hash2);
    }).timeout(300000);
});
