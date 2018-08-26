

const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TotalSupply=1000000000000000000000000000;

contract('TestTwoKeyEconomy', async (accounts) => {
    it('Case 1 Admin Initial Balance_Positive_TestCase', async () => {
        let economy = await TwoKeyEconomy.new();

        const expected =  await economy.totalSupply(); 

        let initialBalance = await economy.balanceOf(accounts[0]);
        assert.equal(initialBalance, expected, 'Owner should have '+ expected+   ' Coins initially');
    });

    it('Case 2 Admin Initial_Balance_Negative_TestCase', async () => {
        let economy = await TwoKeyEconomy.new();
        const expected =  await economy.totalSupply();
        const not_expected = expected / 10;

        let initialBalance = await economy.balanceOf(accounts[0]);
        assert.notEqual(initialBalance, not_expected, 'Owner should have '+ expected + '  Coins initially');
    });

     it('Case 3 Total_Supply_Positive_TestCase', async () => {
        let economy = await TwoKeyEconomy.new();
        const expected =  TotalSupply;

        let totalSupply = await economy.totalSupply();
        assert.equal(totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
    });


      it('Case 4 Total_Supply_Negative_TestCase', async () => {
        let economy = await TwoKeyEconomy.new();
        const expected =  TotalSupply/10;

        let totalSupply = await economy.totalSupply();
        assert.notEqual(totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
    });
    
});
