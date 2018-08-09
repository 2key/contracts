const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");

contract('TestTwoKeyEconomy', async (accounts) => {
    it('Initial Balance', async () => {
        let economy = await TwoKeyEconomy.new();

        const expected = 1000000000000000000000000000;

        let initialBalance = await economy.balanceOf(accounts[0]);
        assert.equal(initialBalance, expected, 'Owner should have 1000000000000000000000000000 Coin initially');
    });
});
