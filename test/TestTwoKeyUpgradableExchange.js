const { ether } = require('./helpers/ether');
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyUpgradableExchange = artifacts.require("TwoKeyUpgradableExchange");
const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");
const TwoKeyReg = artifacts.require("TwoKeyReg");


const BigNumber = web3.BigNumber;

const should = require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .should();

    contract('TwoKeyUpgradableExchange', async (accounts) => {
        let tryCatch = require("./exceptions.js").tryCatch;
        let errTypes = require("./exceptions.js").errTypes;
        let adminContract;
        let exchangeContarct;
        let eventSourceContractForReg;
        let regContract;
        let economyContract;
        let deployerAddress = '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
        let not_admin = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';
        const null_address = '0x0000000000000000000000000000000000000000';   

        before(async() => {
            let adminContractForReg = await TwoKeyAdmin.new(deployerAddress); 
            eventSourceContractForReg = await TwoKeyEventSource.new(adminContractForReg.address);
            regContract = await TwoKeyReg.new(eventSourceContractForReg.address, adminContractForReg.address);
        });

        /// TwokeyAdmin should be assigned as Admin Role for TwoKeyUpgradableExchange
        it('Case 1 : TwokeyAdmin should be assigned as Admin Role for TwoKeyUpgradableExchange', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress); 
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              let exchange =  await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              let isAdmin = await exchange.hasRole(adminContract.address, "admin");
              assert.equal(isAdmin, true, "should be the admin");
        });

        /// Any accont holder other than the TwoKeyUpgradableExchange should not be assigned as Admin Role for TwoKeyUpgradableExchange
        it('Case 2 : Any accont holder other than the TwoKeyUpgradableExchange should not be assigned as Admin Role for TwoKeyUpgradableExchange ', async () => {
              let adminContract =  await TwoKeyAdmin.new(deployerAddress);
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              let isAdmin = await exchange.hasRole(accounts[0], "admin");
              assert.notEqual(isAdmin, true, "should not be the admin");
        });

        /// An error is expected when nulll address is passed in twoKeyUpgradableExchange constructor     
        it('Case 3 : Initial :: Null-Admin-TestCase', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              await tryCatch(TwoKeyUpgradableExchange.new(1, null_address, economyContract.address,adminContract.address), errTypes.anyError)
        });

       
        /// Buying Tokens Method should work in this test case
        it('Case 4 : Buy Token Positive Test Case', async () => {
            let investor = '0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1'; // accounts[1];
            let wallet = deployerAddress;   // accounts[2];
            let purchaser = '0xffcf8fdee72ac11b5c542428b35eef5769c409f0'; // accounts[3];
            let adminAcc = deployerAddress; // accounts[4];

            const rate = new BigNumber(2);
            const value = 10000;

            let expectedTokenAmount = rate.mul(value);

            let adminContract = await TwoKeyAdmin.new(adminAcc);
            let economyContract = await TwoKeyEconomy.new(adminContract.address); 
            let balance = await economyContract.balanceOf(adminContract.address);
            let twoKeyUpgradeableExchangeContract = await TwoKeyUpgradableExchange.new(rate, wallet, economyContract.address, adminContract.address);

            await adminContract.setSingletones(economyContract.address,twoKeyUpgradeableExchangeContract.address,regContract.address, eventSourceContractForReg.address);
            await adminContract.transferByAdmins(twoKeyUpgradeableExchangeContract.address, balance);
            // await economyContract.transfer(twoKeyUpgradeableExchangeContract.address, balance);

            // contract accepts payments
            await twoKeyUpgradeableExchangeContract.send(value);

            await twoKeyUpgradeableExchangeContract.buyTokens(investor, { value: value});
            let balanceOfInvestor = await economyContract.balanceOf(investor);
            assert.equal(balanceOfInvestor.c[0], expectedTokenAmount.c[0], "balances after buying are not well calculated");
        });

        /// Selling Tokens Method should work in this test case
        it('Case 5 : Sell Token Positive Test Case', async () => {
            let investor = '0x90f8bf6a479f320ead074411a4b0e7944ea8c9c1'; // accounts[1];
            let wallet = deployerAddress;   // accounts[2];
            let purchaser = '0xffcf8fdee72ac11b5c542428b35eef5769c409f0'; // accounts[3];
            let adminAcc = deployerAddress; // accounts[4];

            const rate = new BigNumber(2);
            const value = 10000;
            let expectedTokenAmount = rate.mul(value);
            
            let adminContract = await TwoKeyAdmin.new(adminAcc);
            let economyContract = await TwoKeyEconomy.new(adminContract.address);                 /// change to economy contract
            let balance = await economyContract.balanceOf(adminContract.address);       /// check balance
            let twoKeyUpgradeableExchangeContract = await TwoKeyUpgradableExchange.new(rate, wallet, economyContract.address, adminContract.address);

            await adminContract.setSingletones(economyContract.address,twoKeyUpgradeableExchangeContract.address,regContract.address, eventSourceContractForReg.address);
            await adminContract.transferByAdmins(twoKeyUpgradeableExchangeContract.address, balance);

            // contract accepts payments
            await twoKeyUpgradeableExchangeContract.send(value);
            await twoKeyUpgradeableExchangeContract.buyTokens(deployerAddress, { value: value});            

            // sell tokens
            //const tokens = 100;

            let etherBalanceOfInvestor = await adminContract.getEtherBalanceOfAnAddress(investor);
            let expectedEtherAmount = 50; //tokens.div(rate);
            let total = etherBalanceOfInvestor.add(expectedEtherAmount);

            await economyContract.increaseApproval(twoKeyUpgradeableExchangeContract.address, 100);
            await twoKeyUpgradeableExchangeContract.sellTokens(100);
            balanceOfInvestor = await adminContract.getEtherBalanceOfAnAddress(investor);
 
            assert.equal(balanceOfInvestor.c[0], total.c[0], "balances after buying are not well calculated");
        });

        /// SellTokens should revert with an error if allowance is not approved
        it('Case 6 : Sell Token negative Test Case Should Give Error if Allowace not Approved', async () => {
            const rate = new BigNumber(2);
            const value = 10000;
            
            let adminContract = await TwoKeyAdmin.new(deployerAddress);
            let economyContract = await TwoKeyEconomy.new(adminContract.address);                 /// change to economy contract
            let balance = await economyContract.balanceOf(adminContract.address);       /// check balance
            let twoKeyUpgradeableExchangeContract = await TwoKeyUpgradableExchange.new(rate, deployerAddress, economyContract.address, adminContract.address);

            await adminContract.setSingletones(economyContract.address,twoKeyUpgradeableExchangeContract.address,regContract.address, eventSourceContractForReg.address);
            await adminContract.transferByAdmins(twoKeyUpgradeableExchangeContract.address, balance);

            await twoKeyUpgradeableExchangeContract.send(value);
            await twoKeyUpgradeableExchangeContract.buyTokens(deployerAddress, { value: value});            

            await tryCatch(twoKeyUpgradeableExchangeContract.sellTokens(100), errTypes.anyError);
        });

        /// SellTokens should revert if wallet have insufficiant token balance
        it('Case 7 : Sell Token negative Test Case Should Give Error if Wallet Holder Does not have token balance', async () => {
            const rate = new BigNumber(2);
            const value = 10000;
            let purchaser = '0xffcf8fdee72ac11b5c542428b35eef5769c409f0'; // accounts[3];
            
            let adminContract = await TwoKeyAdmin.new(deployerAddress);
            let economyContract = await TwoKeyEconomy.new(adminContract.address);                 /// change to economy contract
            let balance = await economyContract.balanceOf(adminContract.address);       /// check balance
            let twoKeyUpgradeableExchangeContract = await TwoKeyUpgradableExchange.new(rate, deployerAddress, economyContract.address, adminContract.address);

            await adminContract.setSingletones(economyContract.address,twoKeyUpgradeableExchangeContract.address,regContract.address, eventSourceContractForReg.address);
            await adminContract.transferByAdmins(twoKeyUpgradeableExchangeContract.address, balance);

            await twoKeyUpgradeableExchangeContract.send(value);
            await twoKeyUpgradeableExchangeContract.buyTokens(purchaser, { value: value});            

            await economyContract.increaseApproval(twoKeyUpgradeableExchangeContract.address, 100);
            await tryCatch(twoKeyUpgradeableExchangeContract.sellTokens(100), errTypes.anyError);
        });

        /// SellTokens should revert if exchange is upgraded to new exchange before
        it('Case 8 : Sell Token negative Test Case Should Give Error if Only Alive is False', async () => {
            const rate = new BigNumber(2);
            const value = 10000;
            
            let adminContract = await TwoKeyAdmin.new(deployerAddress);
            let economyContract = await TwoKeyEconomy.new(adminContract.address);                 /// change to economy contract
            let balance = await economyContract.balanceOf(adminContract.address);       /// check balance
            let twoKeyUpgradeableExchangeContract = await TwoKeyUpgradableExchange.new(rate, deployerAddress, economyContract.address, adminContract.address);
 
            await adminContract.setSingletones(economyContract.address,twoKeyUpgradeableExchangeContract.address,regContract.address, eventSourceContractForReg.address);
            await adminContract.transferByAdmins(twoKeyUpgradeableExchangeContract.address, balance);

            await twoKeyUpgradeableExchangeContract.send(value);
            await twoKeyUpgradeableExchangeContract.buyTokens(deployerAddress, { value: value});

            let adminContract_new = await TwoKeyAdmin.new(deployerAddress);
            let economyContract_new = await TwoKeyEconomy.new(adminContract.address);
            let twoKeyUpgradeableExchangeContract_new = await TwoKeyUpgradableExchange.new(rate, deployerAddress, economyContract_new.address, adminContract_new.address);
            await adminContract.upgradeEconomyExchangeByAdmins(twoKeyUpgradeableExchangeContract_new.address);           
            await economyContract.increaseApproval(twoKeyUpgradeableExchangeContract.address, 100);
            await tryCatch(twoKeyUpgradeableExchangeContract.sellTokens(100), errTypes.anyError);
        });

        /// SellTokens should revert if wallet have insufficiant ether balance
        it('Case 9 : Sell Token negative Test Case Should Give Error Wallet has less Wei than Token Price', async () => {
            const rate = new BigNumber(2);
            const value = 1000;
            
            let adminContract = await TwoKeyAdmin.new(deployerAddress);
            let economyContract = await TwoKeyEconomy.new(adminContract.address);                 /// change to economy contract
            let balance = await economyContract.balanceOf(adminContract.address);       /// check balance
            let twoKeyUpgradeableExchangeContract = await TwoKeyUpgradableExchange.new(rate, deployerAddress, economyContract.address, adminContract.address);
            await adminContract.setSingletones(economyContract.address,twoKeyUpgradeableExchangeContract.address,regContract.address, eventSourceContractForReg.address);
            await adminContract.transferByAdmins(twoKeyUpgradeableExchangeContract.address, balance);

            await twoKeyUpgradeableExchangeContract.send(value);
            await twoKeyUpgradeableExchangeContract.buyTokens(deployerAddress, { value: value});

            let adminContract_new = await TwoKeyAdmin.new(deployerAddress);
            let economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
            let twoKeyUpgradeableExchangeContract_new = await TwoKeyUpgradableExchange.new(rate, deployerAddress, economyContract_new.address, adminContract_new.address);
            await adminContract_new.setSingletones(economyContract_new.address,twoKeyUpgradeableExchangeContract_new.address,regContract.address, eventSourceContractForReg.address);

            await adminContract.upgradeEconomyExchangeByAdmins(twoKeyUpgradeableExchangeContract_new.address);           
            await economyContract.increaseApproval(twoKeyUpgradeableExchangeContract.address, 1000000);
            await tryCatch(twoKeyUpgradeableExchangeContract.sellTokens(100), errTypes.anyError);
        });

        /// Upgrade Exchange should set filler with value when in alive state
        it('Case 10 : Upgrade Exchange Test Case Should set filler with value when Alive', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              await adminContract.setSingletones(economyContract.address,exchange.address,regContract.address, eventSourceContractForReg.address);

              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address, adminContract_new.address);
        
              await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
              let filler = await exchange.getFiller();
              assert.equal(filler, exchange_new.address, "filler should be equal to "+ exchange_new.address);
        });

        /// Upgrade Exchange Test Case Should give error when not Alive
        it('Case 11 : Upgrade Exchange Test Case Should give error when not Alive', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

              await adminContract.setSingletones(economyContract.address,exchange.address,regContract.address, eventSourceContractForReg.address); 
              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract_new.address);
        
              await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
              await tryCatch(adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address), errTypes.anyError);
        });
        
        /// Should revert if exchange is upgraded i.e. not Alive
        it('Case 12 : Upgrade Exchange Test Case Should give error when not Alive', async () => {
                let adminContract = await TwoKeyAdmin.new(deployerAddress);
                let economyContract = await TwoKeyEconomy.new(adminContract.address);
                let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
                await adminContract.setSingletones(economyContract.address,exchange.address, regContract.address, eventSourceContractForReg.address);
                
                let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
                await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);

                await tryCatch(exchange.upgrade(deployerAddress), errTypes.anyError);
        });
        
        
        /// Upgradable Exchange should not give error when called by admin
        it('Case 13 : Upgrade Exchange Test Case Should not give error when called by admin', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

              await adminContract.setSingletones(economyContract.address,exchange.address,regContract.address, eventSourceContractForReg.address);
              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract_new.address);
        
              await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
              let filler = await exchange.getFiller();
              assert.equal(filler, exchange_new.address, "filler should be equal to "+ exchange_new.address);
        });
        
        /// Upgradable Exchange should give error when called by non admin
        it('Case 14 : Upgrade Exchange Test Case Should give error when called by non admin', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address); 
    
              await adminContract.setSingletones(economyContract.address,exchange.address,regContract.address, eventSourceContractForReg.address);
              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract_new.address);
        
              await tryCatch(exchange.upgrade(exchange_new.address), errTypes.anyError);
        });
        
        /// Fallback payable method when alive should add payable amount to exchange contract balance
        it('Case 15 : Fallback payable method when alive should add payable amount to exchange contract balance', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              await adminContract.setSingletones(economyContract.address,exchange.address,regContract.address, eventSourceContractForReg.address);
              await exchange.send(1000);
              let balance = await adminContract.getEtherBalanceOfAnAddress(exchange.address);
              assert.equal(balance, 1000, "Exchange Balance should be equal to 1000");
        });
        
        /// Fallback payable method when not alive should add payable amount to new exchange contract
        it('Case 16 : Fallback payable method when not alive should add payable amount to new exchange contract', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let economyContract = await TwoKeyEconomy.new(adminContract.address);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
               await adminContract.setSingletones(economyContract.address,exchange.address,regContract.address, eventSourceContractForReg.address);

              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, economyContract.address,adminContract_new.address);
        
              await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
              await exchange.send(1000);
        
              let exchange_balance = await adminContract.getEtherBalanceOfAnAddress(exchange.address);
              let exchange_new_balance = await adminContract.getEtherBalanceOfAnAddress(exchange_new.address);
        
              assert.notEqual(exchange_balance, 1000, "Exchange Balance should not be equal to 1000");
              assert.equal(exchange_balance, 0, "Exchange Balance should not be equal to 0");
              assert.equal(exchange_new_balance, 1000, "Exchange Balance should not be equal to 1000");
        });
});
