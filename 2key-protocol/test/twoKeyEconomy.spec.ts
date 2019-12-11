import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {TwoKeyProtocol} from "../src";
import {expect} from "chai";
const { env } = process;
require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');
const rpcUrls = [env.RPC_URL];
const networkId = parseInt(env.MAIN_NET_ID, 10);
const privateNetworkId = parseInt(env.SYNC_NET_ID, 10);
const eventsNetUrls = [env.PLASMA_RPC_URL];

let twoKeyProtocol: TwoKeyProtocol;
let from: string;

const web3switcher = {
    deployer: () => createWeb3(env.MNEMONIC_DEPLOYER, rpcUrls),
    aydnep: () => createWeb3(env.MNEMONIC_AYDNEP, rpcUrls),
    gmail: () => createWeb3(env.MNEMONIC_GMAIL, rpcUrls),
    test4: () => createWeb3(env.MNEMONIC_TEST4, rpcUrls),
    renata: () => createWeb3(env.MNEMONIC_RENATA, rpcUrls),
    uport: () => createWeb3(env.MNEMONIC_UPORT, rpcUrls),
    gmail2: () => createWeb3(env.MNEMONIC_GMAIL2, rpcUrls),
    aydnep2: () => createWeb3(env.MNEMONIC_AYDNEP2, rpcUrls),
    test: () => createWeb3(env.MNEMONIC_TEST, rpcUrls),
    guest: () => createWeb3('mnemonic words should be here bu   t for some reason they are missing', rpcUrls),
};


/**
 * Tests for TwoKeyEconomy contract
 */
describe('Tests for TwoKeyEconomy ERC20 contract' , () => {
    it('should check token name', async() => {
        const {web3, address} = web3switcher.deployer();
        from = address;
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_DEPLOYER).privateKey,
            networkId,
            privateNetworkId,
        });

        let tokenName = await twoKeyProtocol.ERC20.getTokenName(twoKeyProtocol.twoKeyEconomy.address);
        expect(tokenName).to.be.equal("TwoKeyEconomy");
    }).timeout(60000);

    it('should check total supply of tokens', async() => {
        let totalSupply = await twoKeyProtocol.ERC20.getTotalSupply(twoKeyProtocol.twoKeyEconomy.address);
        expect(totalSupply).to.be.equal(600000000); //6 Milion total tokens
    }).timeout(60000);

    it('should validate that TwoKeyUpgradableExchange contract received 3% of total supply',async() => {
        let balance = await twoKeyProtocol.ERC20.getERC20Balance(
            twoKeyProtocol.twoKeyEconomy.address,
            twoKeyProtocol.twoKeyUpgradableExchange.address
        );
        let totalSupply = await twoKeyProtocol.ERC20.getTotalSupply(twoKeyProtocol.twoKeyEconomy.address);
        expect(balance).to.be.equal(totalSupply*(0.03));
    }).timeout(60000);


    it('should validate that TwoKeyParticipationMiningPool contract received 20% of total supply',async() => {
        let balance = await twoKeyProtocol.ERC20.getERC20Balance(
            twoKeyProtocol.twoKeyEconomy.address,
            twoKeyProtocol.twoKeyParticipationMiningPool.address
        );
        let totalSupply = await twoKeyProtocol.ERC20.getTotalSupply(twoKeyProtocol.twoKeyEconomy.address);
        expect(balance).to.be.equal(totalSupply*(0.20));
    }).timeout(60000);

    it('should validate that TwoKeyNetworkGrowthFund contract received 20% of total supply',async() => {
        let balance = await twoKeyProtocol.ERC20.getERC20Balance(
            twoKeyProtocol.twoKeyEconomy.address,
            twoKeyProtocol.twoKeyNetworkGrowthFund.address
        );
        let totalSupply = await twoKeyProtocol.ERC20.getTotalSupply(twoKeyProtocol.twoKeyEconomy.address);
        expect(balance).to.be.equal(totalSupply*(0.16));
    }).timeout(60000);

    it('should validate that TwoKeyMPSNMiningPool contract received 10% of total supply',async() => {
        let balance = await twoKeyProtocol.ERC20.getERC20Balance(
            twoKeyProtocol.twoKeyEconomy.address,
            twoKeyProtocol.twoKeyMPSNMiningPool.address
        );
        let totalSupply = await twoKeyProtocol.ERC20.getTotalSupply(twoKeyProtocol.twoKeyEconomy.address);
        expect(balance).to.be.equal(totalSupply*(0.10));
    }).timeout(60000);

    it('should validate that TwoKeyTeamGrowthFund contract received 4% of total supply',async() => {
        let balance = await twoKeyProtocol.ERC20.getERC20Balance(
            twoKeyProtocol.twoKeyEconomy.address,
            twoKeyProtocol.twoKeyTeamGrowthFund.address
        );
        let totalSupply = await twoKeyProtocol.ERC20.getTotalSupply(twoKeyProtocol.twoKeyEconomy.address);
        expect(balance).to.be.equal(totalSupply*(0.04));
    }).timeout(60000);

    it('should validate that TwoKeyAdmin contract received 47% of total supply',async() => {
        let balance = await twoKeyProtocol.ERC20.getERC20Balance(
            twoKeyProtocol.twoKeyEconomy.address,
            twoKeyProtocol.twoKeyAdmin.address
        );
        let totalSupply = await twoKeyProtocol.ERC20.getTotalSupply(twoKeyProtocol.twoKeyEconomy.address);
        expect(balance).to.be.equal(totalSupply*(0.47));
    }).timeout(60000);



});

