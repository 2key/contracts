import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {TwoKeyProtocol} from "../src";
import {expect} from "chai";
const { env } = process;
require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');
const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const eventsNetUrl = env.PLASMA_RPC_URL;

let twoKeyProtocol: TwoKeyProtocol;
let from: string;

const web3switcher = {
    deployer: () => createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl),
    aydnep: () => createWeb3(env.MNEMONIC_AYDNEP, rpcUrl),
    gmail: () => createWeb3(env.MNEMONIC_GMAIL, rpcUrl),
    test4: () => createWeb3(env.MNEMONIC_TEST4, rpcUrl),
    renata: () => createWeb3(env.MNEMONIC_RENATA, rpcUrl),
    uport: () => createWeb3(env.MNEMONIC_UPORT, rpcUrl),
    gmail2: () => createWeb3(env.MNEMONIC_GMAIL2, rpcUrl),
    aydnep2: () => createWeb3(env.MNEMONIC_AYDNEP2, rpcUrl),
    test: () => createWeb3(env.MNEMONIC_TEST, rpcUrl),
    guest: () => createWeb3('mnemonic words should be here bu   t for some reason they are missing', rpcUrl),
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
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_DEPLOYER).privateKey,
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
});

