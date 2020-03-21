import '../constants/polifils';

import {expect} from "chai";
import {describe, it} from "mocha";
import availableUsers from "../constants/availableUsers";

const {protocol: twoKeyProtocol} = availableUsers.deployer;

/**
 * Tests for TwoKeyEconomy contract
 */
describe('Tests for TwoKeyEconomy ERC20 contract' , () => {
    it('should check token name', async() => {
        let tokenName = await twoKeyProtocol.ERC20.getTokenName(twoKeyProtocol.twoKeyEconomy.address);
        expect(tokenName).to.be.equal("TwoKeyEconomy");
    }).timeout(60000);

    it('check for correct symbol', async () => {
        const tokenSymbol = await twoKeyProtocol.ERC20.getERC20Symbol(twoKeyProtocol.twoKeyEconomy.address);
        expect(tokenSymbol).to.be.equal('2KEY');
    }).timeout(10000);

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
