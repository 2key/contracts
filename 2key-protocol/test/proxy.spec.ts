import { TwoKeyProtocol } from '../src';
import createWeb3 from './_web3';
import Sign from '../src/utils/sign';
import contractsMeta from '../src/contracts';

const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;

let twoKeyProtocol;

const { web3, address } = createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl);
twoKeyProtocol = new TwoKeyProtocol({
    web3,
    address,
    networks: {
        mainNetId,
        syncTwoKeyNetId,
    },
    plasmaPK: Sign.generatePrivateKey().toString('hex'),
});

const eventsInstance = web3.eth.contract(contractsMeta.TwoKeyEventSource.abi).at(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
const events = eventsInstance.allEvents();

events.watch((err, res) => {
    console.log('Event:', err, res);
});

console.log('Press any key to exit');

process.stdin.setRawMode(true);
process.stdin.resume();
process.stdin.on('data', process.exit.bind(process, 0));
