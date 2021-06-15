const { expect } = require("chai");
const { truffleAssert, BigNumber, awaitTx, waitForSomeTime } = require("./utils");

const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');

contract("TwoKeyEconomy", async (accounts) => {

    const TOKEN_NAME = 'TwoKeyEconomy';
    const TOKEN_SYMBOL = '2KEY';
    const TOKEN_DECIMALS = 18;
    
    let twoKeyEconomy;

    beforeEach(async function() {
        twoKeyEconomy = await TwoKeyEconomy.deployed();
    });

    it('Token name should be properly set', async () => {
        let name = await twoKeyEconomy.name();
        expect(name).to.equal(TOKEN_NAME);
    });

    it('Token symbol should be properly set', async () => {
        let symbol = await twoKeyEconomy.symbol();
        expect(symbol).to.equal(TOKEN_SYMBOL);
    });

    it('Token decimals should be properly set', async () => {
        let decimals = await twoKeyEconomy.decimals();
        expect(decimals.eq(BigNumber.from(TOKEN_DECIMALS))).to.be.true;
    });

    it('Should not freeze transfer (by non TwoKeyAdmin)', async () => {
        await truffleAssert.reverts(twoKeyEconomy.freezeTransfers());
    });

    it('Should not unfreeze transfer (by non TwoKeyAdmin)', async () => {
        await truffleAssert.reverts(twoKeyEconomy.unfreezeTransfers());
    });
});
