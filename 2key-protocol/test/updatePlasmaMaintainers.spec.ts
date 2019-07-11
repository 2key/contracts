import 'mocha';
require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

import {TwoKeyProtocol} from '../src';
import web3switcher from './_web3';
import {promisify} from '../src/utils/promisify';

const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
console.log(mainNetId);

// const gasPrice = process.env.GASPRICE || 5000000000;
console.log(rpcUrl);
console.log(mainNetId);

describe('TwoKeyProtocol', () => {
    it(`should add ${process.argv[7]} as plasma maintainer`, async() => {
        const { web3, address } = await web3switcher(rpcUrl, rpcUrl, '6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1');
        const twoKeyProtocol = new TwoKeyProtocol({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: 'd718529bf9e0a5365e3a3545b66a612ff29be12aba366b6e6e919bef1d3b83e2',
        });
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: 'd718529bf9e0a5365e3a3545b66a612ff29be12aba366b6e6e919bef1d3b83e2',
        });
        console.log('FROM', twoKeyProtocol.plasmaAddress, twoKeyProtocol.twoKeyPlasmaEvents.address);
        const txHash = await promisify(twoKeyProtocol.twoKeyPlasmaEvents.addMaintainers, [[process.argv[7]], { from: twoKeyProtocol.plasmaAddress, gasPrice: 0 }]);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash, { web3: twoKeyProtocol.plasmaWeb3 });
    }).timeout(300000);
});
