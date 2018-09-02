
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyExchange = artifacts.require("TwoKeyUpgradableExchange");
const ERC20TokenMock = artifacts.require('ERC20TokenMock');



   contract('TestTwoKeyEconomy', async (accounts) => {

        let adminContract;
        let exchangeContarct;
        let erc20MockContract;
        let deployerAdrress = '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
        const null_address = '0x0000000000000000000000000000000000000000';   
        const tokenname = 'TwoKeyEconomy';
        const  symbol= '2Key';
        const  decimals= 18;
        const totalSupply=1000000000000000000000000000;    

        before(async() => {
              erc20MockContract = await ERC20TokenMock.new();
              exchangeContarct = await TwoKeyExchange.new(1, deployerAdrress, erc20MockContract.address);
              adminContract = await TwoKeyAdmin.new(deployerAdrress, exchangeContarct.address); 
         });



       it('Case 1 : TwokeyAdmin should be assigned as Admin Role for TwoKeyEconomy', async () => {
             let economy = await TwoKeyEconomy.new(adminContract.address);
             let isAdmin = await economy.hasRole(adminContract.address, "admin");
              assert.equal(isAdmin, true, "should be the admin");
            
        });

     it('Case 2 : Any accont holder othe than the TwokeyAdmin should not be assigned as Admin Role for TwoKeyEconomy ', async () => {
             let economy = await TwoKeyEconomy.new(adminContract.address);
             let isAdmin = await economy.hasRole(accounts[0], "admin");
              assert.notEqual(isAdmin, true, "should not be the admin");
        });

     it('Case 3 : TwoKeyAdmin account should be assigned Initial Balance', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const noExpected =  0; 
            let initialBalance = await economy.balanceOf(adminContract.address);
            assert.notEqual(initialBalance, noExpected, 'Two Key Admin  should have '+ initialBalance+   ' Coins initially ' );
        });

     it('Case 4 : Deployer account should not be assigned Initial Balance', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const expected =  0; 
            let initialBalance = await economy.balanceOf(accounts[0]);
            assert.equal(initialBalance, expected, 'Deployer account should have '+ 0 +   ' Coins initially ' );
        });

       it('Case 5: TwoKeyAdmin account initial balance positive testCase', async () => {
                let economy = await TwoKeyEconomy.new(adminContract.address);
                const expected =  await economy.totalSupply(); 
                let initialBalance = await economy.balanceOf(adminContract.address);
                assert.equal(initialBalance, expected, 'TwoKeyAdmin should have '+ expected+   ' Coins initially');
       });

        
        it('Case 6 : TwoKeyAdmin account initial balance positive negative testCase', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const expected =  await economy.totalSupply();
            const not_expected = expected / 10;

            let initialBalance = await economy.balanceOf(adminContract.address);
            assert.notEqual(initialBalance, not_expected, 'TwoKeyAdmin should have '+ expected + '  Coins initially');
        });

          it('Case 7 : totalSupply positive test case', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const expected =  totalSupply;

            let _totalSupply = await economy.totalSupply();
            assert.equal (_totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
        });


        it('Case 8 : tokenname positive test case', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const expected =  tokenname

            l//et totalSupply = await economy.totalSupply();
            //assert.notEqual(totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
        });  

     it('Case 9 : tokenname negative test case', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const notEexpected =  "xxxx";

            //let totalSupply = await economy.totalSupply();
           // assert.notEqual(totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
        });  


        it('Case 10 : symbol positive test case', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const expected =  symbol

            l//et totalSupply = await economy.totalSupply();
            //assert.notEqual(totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
        });  

     it('Case 11 : symbol negative test case', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const notEexpected =  "xxxx";

            //let totalSupply = await economy.totalSupply();
           // assert.notEqual(totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
        });  


        it('Case 12 : decimals positive test case', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const expected =  decimals

            l//et totalSupply = await economy.totalSupply();
            //assert.notEqual(totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
        });  

     it('Case 13 : decimals negative test case', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            const notEexpected =  10;

            //let totalSupply = await economy.totalSupply();
           // assert.notEqual(totalSupply, expected, 'Owner should have '+ expected+   ' Total Supply');
        });  

  it('Case 14 : TwoKeyAdmin should have  two key economy object', async () => {
            let economy = await TwoKeyEconomy.new(adminContract.address);
            let economyFromAdmin= adminContract.GetTwoKeyEconomy();
            assert.equal(economy.address, economyFromAdmin.address, 'TwoKeyAdmin should have  two key economy object');
        });  


       
});

