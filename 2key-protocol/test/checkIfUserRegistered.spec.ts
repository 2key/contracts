import 'mocha';
import {TwoKeyProtocol} from '../src';
import createWeb3 from './_web3';
import Sign from '../src/sign';
require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');



//  RINKEBY=true yarn run test:one 2key-protocol/test/updateTwoKeyReg.spec.ts "0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7:2key13:Andrii Pindiura:aydnep@aydnep.com.ua"


const rpcUrl = process.env.RINKEBY ? 'https://rpc.public.test.k8s.2key.net' : 'wss://ropsten.infura.io/ws';
// const rpcUrl = 'wss://ropsten.infura.io/ws';
const networkId = parseInt(process.env.MAIN_NET_ID, 10);
const privateNetworkId = parseInt(process.env.SYNC_NET_ID, 10);

const network = process.env.RINKEBY ? 'RINKEBY' : 'ROPSTEN';

describe(`TwoKeyProtocol ${network}`, () => {
    it('check if user registered in TwoKeyRegistry', async() => {
        const userAddress = process.argv[7];
        const userName = process.argv[8];
        const { web3 } = createWeb3('laundry version question endless august scatter desert crew memory toy attract cruel', [rpcUrl]);
        const twoKeyProtocol = new TwoKeyProtocol({
            web3,
            plasmaPK: Sign.generatePrivateKey(),
            networkId,
            privateNetworkId,
        });
        const isAddressRegistered = await twoKeyProtocol.Registry.checkIfAddressIsRegistered(userAddress);
        const isUserRegistered = await twoKeyProtocol.Registry.checkIfUserIsRegistered(userName);
        console.log('User2Address', isUserRegistered);
        console.log(`Address ${userAddress} ${isAddressRegistered ? 'REGISTERED' : 'NOT REGISTERED'} in TwoKeyReg`);
    }).timeout(300000);
});
