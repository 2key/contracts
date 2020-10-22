import TwoKeyIPFS from "../src/utils/ipfs";

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');
import chai from 'chai';
import promisedChai from 'chai-as-promised';
import { rpcUrls, eventsUrls } from './constants/smallConstants';
import createWeb3 from './helpers/_web3'
import { promisify } from '../src/utils/promisify';
import Contracts from '../src/contracts/singletons';

const { env } = process;
const expect = chai.expect;
chai.use(promisedChai);

describe('Web3 v1.3.0', () => {
    const { web3, address } = createWeb3(env.MNEMONIC_DEPLOYER, rpcUrls, eventsUrls);
    let estimate;
    let tx;

    it('get current account', async () => {
        // const tx = {
        //     to: env.AYDNEP_ADDRESS,
        //     from: address,
        //     value: web3.utils.toWei('1', 'ether'),
        //     gas: 21000,
        // }
        // console.log('TX', tx);
        // const txHash = await promisify(web3.eth.sendTransaction,[tx]);
        // console.log(await promisify(web3.eth.getTransaction, [txHash]));
        // console.log('Accounts', );
        // console.log('Accounts', web3.eth.defaultAccount);
        expect(web3.eth.accounts.wallet['0'] && web3.eth.accounts.wallet['0'].address.toLowerCase())
            .to.be.equals('0xb3fa520368f2df7bed4df5185101f303f6c7decc');
    }).timeout(30000);

    it('should estimate ETH transfer', async () => {
        tx = {
            to: env.AYDNEP_ADDRESS,
            from: address,
            value: web3.utils.toWei('1', 'ether'),
        };
        estimate = await promisify(web3.eth.estimateGas, [tx]);
        expect(estimate).to.be.gte(21000);
    }).timeout(30000);

    it('send 1 ETH', async () => {
        tx.gas = estimate;
        const txHash = await promisify(web3.eth.sendTransaction,[tx]);
        const receipt = await promisify(web3.eth.getTransaction, [txHash])
        expect(receipt.value).to.be.equals(web3.utils.toWei('1', 'ether'));
    }).timeout(30000);

    it('get 2key balance', async () => {
        const contractDeployedAddress = Contracts.TwoKeyEconomy.networks[env.MAIN_NET_ID].Proxy || Contracts.TwoKeyEconomy.networks[env.MAIN_NET_ID].address;
        const economy = new web3.eth.Contract(Contracts.TwoKeyEconomy.abi, contractDeployedAddress);
        const balance = await promisify(economy.methods.balanceOf, [address]);
        console.log('BALANCE', balance);
        expect(balance).to.be.equals('0');
    }).timeout(30000);

    it('should create a proposal', async () => {
        const contractDeployedAddress = Contracts.TwoKeyCongress.networks[env.MAIN_NET_ID].Proxy || Contracts.TwoKeyCongress.networks[env.MAIN_NET_ID].address;
        const adminAddress = Contracts.TwoKeyAdmin.networks[env.MAIN_NET_ID].Proxy || Contracts.TwoKeyAdmin.networks[env.MAIN_NET_ID].address;
        const congress = new web3.eth.Contract(Contracts.TwoKeyCongress.abi, contractDeployedAddress);
        // console.log('NEW_PROPOSAL', JSON.stringify(congress._jsonInterface));
        console.log(await promisify(congress.methods.newProposal, [
            adminAddress,
            0,
            'Send some tokens to contractor',
            '0x9ffe94d9000000000000000000000000bae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7000000000000000000000000000000000000000000084595161401484a000000',
            { from: address }
        ]));
        // expect(receipt.value).to.be.equals(web3.utils.toWei('1', 'ether'));
    }).timeout(30000);
});
