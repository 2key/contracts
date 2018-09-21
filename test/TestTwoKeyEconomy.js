
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyExchange = artifacts.require("TwoKeyUpgradableExchange");


const BigNumber = web3.BigNumber;

   contract('TestTwoKeyEconomy', async (accounts) => {

        let adminContract;
        let exchangeContarct;
        let deployerAdrress = '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
        const null_address = '0x0000000000000000000000000000000000000000';   
        const tokenName = 'TwoKeyEconomy';
        const  symbol = '2Key';
        const  decimals = 18;
        const totalSupply = 1000000000000000000000000;

        before(async() => {
              adminContract = await TwoKeyAdmin.new(deployerAdrress); 
        });

        /// TwokeyAdmin should be assigned as Admin Role for TwoKeyEconomy
        it('Case 1 : TwokeyAdmin should be assigned as Admin Role for TwoKeyEconomy', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              let isAdmin = await economy.hasRole(adminContract.address, "admin");
              assert.equal(isAdmin, true, "should be the admin");
        });

        /// Any accont holder other than the TwokeyAdmin should not be assigned as Admin Role for TwoKeyEconomy
        it('Case 2 : Any accont holder other than the TwokeyAdmin should not be assigned as Admin Role for TwoKeyEconomy ', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              let isAdmin = await economy.hasRole(accounts[0], "admin");
              assert.notEqual(isAdmin, true, "should not be the admin");
        });

        /// TwoKeyAdmin account should be assigned Initial Balance
        it('Case 3 : TwoKeyAdmin account should be assigned Initial Balance', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const notExpected =  0; 
              let initialBalance = await economy.balanceOf(adminContract.address);
              assert.notEqual(initialBalance, notExpected, 'Two Key Admin  should have '+ initialBalance+   ' Coins initially ' );
        });

        /// Deployer account should not be assigned Initial Balance
        it('Case 4 : Deployer account should not be assigned Initial Balance', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const expected =  0; 
              let initialBalance = await economy.balanceOf(accounts[0]);
              assert.equal(initialBalance, expected, 'Deployer account should have '+ 0 +   ' Coins initially ' );
        });

        /// TwoKeyAdmin account initial balance positive testCase
        it('Case 5 : TwoKeyAdmin account initial balance positive testCase', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
                
              let expected =  await economy.totalSupply();
              let expected_string = JSON.stringify(expected);
                
              let initialBalance = await economy.balanceOf(adminContract.address);
              let initialBalance_string = JSON.stringify(initialBalance);
                
              assert.equal(expected_string, initialBalance_string, 'TwoKeyAdmin should have '+ expected+   ' Coins initially');
        });

        /// TwoKeyAdmin account initial balance negative testCase
        it('Case 6 : TwoKeyAdmin account initial balance negative testCase', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const expected =  await economy.totalSupply();
              const not_expected = expected / 10;

              let initialBalance = await economy.balanceOf(adminContract.address);
              assert.notEqual(initialBalance, not_expected, 'TwoKeyAdmin should have '+ expected + '  Coins initially');
        });

        /// totalSupply positive test case
        it('Case 7 : totalSupply positive test case', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
                
              const expected = totalSupply;
              let _totalSupply = await economy.totalSupply();
              
              assert.equal (_totalSupply, expected, 'Owner should have '+ expected+  ' Total Supply');
        });

        /// token name positive test case
        it('Case 8 : token name positive test case', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const expected =  tokenName;

              let name = await economy.getTokenName();
              assert.equal(name, expected, 'Owner should have '+ expected + ' Token name');
        });  

        /// token name negative test case
        it('Case 9 : token name negative test case', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const notExpected =  "xxxx";

              let name = await economy.getTokenName();
              assert.notEqual(name, notExpected, 'Owner should not have '+ notExpected+ ' as token name');
        });  

        /// symbol positive test case
        it('Case 10 : symbol positive test case', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const expected = symbol;

              let symbol_val = await economy.getTokenSymbol();

              assert.equal(symbol_val, expected, 'Owner should have '+ expected+ ' as Token symbol');
        });  

        /// symbol negative test case
        it('Case 11 : symbol negative test case', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const notExpected =  "xxxx";

              let symbol = await economy.getTokenSymbol();
              assert.notEqual(symbol, notExpected, 'Owner should not have '+ notExpected + 'as Token symbol');
        });  

        /// decimals positive test case
        it('Case 12 : decimals positive test case', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const expected = decimals;

              let decimal = await economy.getTokenDecimals();

              assert.equal(decimal, expected, 'Owner should have '+ expected+   'Token decimals');
        });  

        /// decimals negative test case
        it('Case 13 : decimals negative test case', async () => {
              let economy = await TwoKeyEconomy.new(adminContract.address);
              const notExpected =  10;

              let totalSupply = await economy.totalSupply();
              assert.notEqual(totalSupply, notExpected, 'Owner should not have '+ notExpected + ' Total Supply');
        });         
});

