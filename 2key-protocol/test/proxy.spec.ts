import createWeb3 from './_web3';
import singletons from '../src/contracts/singletons';

const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;

// let twoKeyProtocol;

const { web3 } = createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl);
const { web3: plasmaWeb3 } = createWeb3(env.MNEMONIC_DEPLOYER, 'https://test.plasma.2key.network/');
// twoKeyProtocol = new TwoKeyProtocol({
//     web3,
//     address,
//     networks: {
//         mainNetId,
//         syncTwoKeyNetId,
//     },
//     plasmaPK: Sign.generatePrivateKey().toString('hex'),
// });

const eventsInstance = web3.eth.contract(singletons.TwoKeyEventSource.abi).at(singletons.TwoKeyEventSource.networks[mainNetId].address);
const events = eventsInstance.allEvents();

const plasmaInstance = plasmaWeb3.eth.contract(singletons.TwoKeyPlasmaEvents.abi).at(singletons.TwoKeyPlasmaEvents.networks[syncTwoKeyNetId].address);
const plasma = plasmaInstance.allEvents();


events.watch((err, res) => {
    console.log('TwoKeyEventSource:', err, res);
});

plasma.watch((err, res) => {
    console.log('TwoKeyPlasmaEvents:', err, res);
});

console.log('Press any key to exit');

process.stdin.setRawMode(true);
process.stdin.resume();
process.stdin.on('data', process.exit.bind(process, 0));
