const { ether } = require('./helpers/ether');
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyUpgradableExchange = artifacts.require("TwoKeyUpgradableExchange");
const ERC20TokenMock = artifacts.require('ERC20TokenMock');


const BigNumber = web3.BigNumber;

const should = require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .should();




    contract('TwoKeyUpgradableExchange', async (accounts) => {
        let tryCatch = require("./exceptions.js").tryCatch;
        let errTypes = require("./exceptions.js").errTypes;
        let adminContract;
        let exchangeContarct;
        let erc20MockContract;
        let deployerAddress = '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
        let not_admin = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';
        const null_address = '0x0000000000000000000000000000000000000000';   

        before(async() => {
              erc20MockContract = await ERC20TokenMock.new();
        });

        /// TwokeyAdmin should be assigned as Admin Role for TwoKeyUpgradableExchange
        it('Case 1 : TwokeyAdmin should be assigned as Admin Role for TwoKeyUpgradableExchange', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress); 
              let exchange =  await TwoKeyUpgradableExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);
              let isAdmin = await exchange.hasRole(adminContract.address, "admin");
              assert.equal(isAdmin, true, "should be the admin");
        });

        /// Any accont holder other than the TwoKeyUpgradableExchange should not be assigned as Admin Role for TwoKeyUpgradableExchange
        it('Case 2 : Any accont holder other than the TwoKeyUpgradableExchange should not be assigned as Admin Role for TwoKeyUpgradableExchange ', async () => {
              let adminContract =  await TwoKeyAdmin.new(deployerAddress);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);
              let isAdmin = await exchange.hasRole(accounts[0], "admin");
              assert.notEqual(isAdmin, true, "should not be the admin");
        });

        /// An error is expected when nulll address is passed in twoKeyUpgradableExchange constructor     
        it('Case 3 : Initial :: Null-Admin-TestCase', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              await tryCatch(TwoKeyUpgradableExchange.new(1, null_address, erc20MockContract.address,adminContract.address), errTypes.anyError)
        });

        /// After successful deployement of upgradable exchange, admin contract should have upgradable exchange object
        it('Case 4 : TwoKeyAdmin should have TwoKeyUpgradableExchange object', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let exchange =  await TwoKeyUpgradableExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);
              let exchangeFromAdmin= await adminContract.getTwoKeyUpgradableExchange(); 
              assert.equal(exchange.address, exchangeFromAdmin, 'TwoKeyAdmin should have two key exchange object');
        });  
      
        /// Selling Tokens Method should work in this test case
        it('Case 5 : Sell Token Positive Test Case', async () => {
            let investor = accounts[1];
            let wallet = accounts[2];
            let purchaser = accounts[3];
            let adminAcc = accounts[4];

            const rate = new BigNumber(2);
            const value = 10000;

            let expectedTokenAmount = rate.mul(value);

            let adminContract = await TwoKeyAdmin.new(adminAcc, {from:adminAcc});

            let tokenContract = await ERC20TokenMock.new();
            let balance = await tokenContract.balanceOf(accounts[0]);
            let twoKeyUpgradeableExchangeContract = await TwoKeyUpgradableExchange.new(rate, wallet, tokenContract.address, adminContract.address);
            await tokenContract.transfer(twoKeyUpgradeableExchangeContract.address, balance);

            // contract accepts payments
            await twoKeyUpgradeableExchangeContract.send(value, { from: purchaser });

            await twoKeyUpgradeableExchangeContract.buyTokens(investor, { value: value, from: purchaser});
            let balanceOfInvestor = await tokenContract.balanceOf(investor);
            assert.equal(balanceOfInvestor.c[0], expectedTokenAmount.c[0], "balances after buying are not well calculated");
        });

        /// SellTokens should revert with an error if allowance is not approved
        it('Case 6 : Sell Token negative Test Case  Should Give Error if Allowace not Approved', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              await exchange.send("1000000000");
              let initialBalance = await mockToken.balanceOf(accounts[0]);
              await tryCatch(exchange.sellTokens(), errTypes.anyError);
        });

        /// SellTokens should revert if wallet have insufficiant token balance
        it('Case 7 : Sell Token negative Test Case  Should Give Error if Wallet Holder Does not have token balance', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              await exchange.send("1000000000");
              let initialBalance = await mockToken.balanceOf(accounts[0]);
              await tryCatch(exchange.sellTokens(), errTypes.anyError);
        });

        // /// SellTokens should revert if exchange is upgraded to new exchange before
        // it('Case 8 : Sell Token negative Test Case  Should Give Error if Only Alive is False', async () => {
        //       let adminContract = await TwoKeyAdmin.new(deployerAddress);
        //       let mockToken = await ERC20TokenMock.new(); //from: deployerAddress
        //       let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
        //       await exchange.send("1000000000");
        //       let initialBalance = await mockToken.balanceOf(accounts[0]);
    
        //       adminContract_new = await TwoKeyAdmin.new(deployerAddress);
        //       economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
        //       // eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
        //       // regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
        //       exchangeContract_new =  await TwoKeyUpgradableExchange.new(1, deployerAddress, erc20MockContract.address, adminContract_new.address);
    
        //       await adminContract.upgradeEconomyExchangeByAdmins(exchangeContract_new.address);
        //       await tryCatch(exchange.sellTokens(), errTypes.anyError);
        // });

        /// SellTokens should revert if wallet have insufficiant ether balance
        it('Case 9 : Sell Token negative Test Case  Should Give Error Wallet has less Wei than Token Price', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              let initialBalance = await mockToken.balanceOf(accounts[0]);
              await tryCatch(exchange.sellTokens(), errTypes.anyError);
        });

        // /// Upgrade Exchange should set filler with value when in alive state
        // it('Case 10 : Upgrade Exchange Test Case Should set filler with value when Alive', async () => {
        //       let adminContract = await TwoKeyAdmin.new(deployerAddress);
        //       let mockToken = await ERC20TokenMock.new();
        //       let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
        //
        //       let adminContract_new = await TwoKeyAdmin.new(not_admin);
        //       let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
        //
        //       await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
        //       let filler = await exchange.getFiller();
        //       assert.equal(filler, exchange_new.address, "filler should be equal to "+ exchange_new.address);
        // });

        // /// Upgrade Exchange Test Case Should give error when not Alive
        // it('Case 11 : Upgrade Exchange Test Case Should give error when not Alive', async () => {
        //       let adminContract = await TwoKeyAdmin.new(deployerAddress);
        //       let mockToken = await ERC20TokenMock.new();
        //       let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
        //
        //       let adminContract_new = await TwoKeyAdmin.new(not_admin);
        //       let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
        //
        //       await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
        //       await tryCatch(adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address), errTypes.anyError);
        // });
        //
        // // /// should check in sol that the address is of type exchange !
        // // it('Case 12 : Upgrade Exchange Test Case Should give error when not Alive', async () => {
        //
        // //           let adminContract = await TwoKeyAdmin.new(deployerAddress);
        // //           let mockToken = await ERC20TokenMock.new();
        // //           let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
        //
        // //           await tryCatch(exchange.upgrade(deployerAddress), errTypes.anyError);
        // // });
        //
        //
        // /// Upgradable Exchange should not give error when called by admin
        // it('Case 13 : Upgrade Exchange Test Case Should not give error when called by admin', async () => {
        //       let adminContract = await TwoKeyAdmin.new(deployerAddress);
        //       let mockToken = await ERC20TokenMock.new();
        //       let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
        //
        //       let adminContract_new = await TwoKeyAdmin.new(not_admin);
        //       let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
        //
        //       await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
        //       let filler = await exchange.getFiller();
        //       assert.equal(filler, exchange_new.address, "filler should be equal to "+ exchange_new.address);
        // });
        //
        // /// Upgradable Exchange should give error when called by non admin
        // it('Case 14 : Upgrade Exchange Test Case Should give error when called by non admin', async () => {
        //       let adminContract = await TwoKeyAdmin.new(deployerAddress);
        //       let mockToken = await ERC20TokenMock.new();
        //       let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
        //
        //       let adminContract_new = await TwoKeyAdmin.new(not_admin);
        //       let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
        //
        //       await tryCatch(exchange.upgrade(exchange_new.address), errTypes.anyError);
        // });
        //
        // /// Fallback payable method when alive should add payable amount to exchange contract balance
        // it('Case 15 : Fallback payable method when alive should add payable amount to exchange contract balance', async () => {
        //       let adminContract = await TwoKeyAdmin.new(deployerAddress);
        //       let mockToken = await ERC20TokenMock.new();
        //       let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
        //
        //       await exchange.send(1000);
        //       let balance = await adminContract.getEtherBalanceOfAnAddress(exchange.address);
        //       assert.equal(balance, 1000, "Exchange Balance should be equal to 1000");
        // });
        //
        // /// Fallback payable method when not alive should add payable amount to new exchange contract
        // it('Case 16 : Fallback payable method when not alive should add payable amount to new exchange contract', async () => {
        //       let adminContract = await TwoKeyAdmin.new(deployerAddress);
        //       let mockToken = await ERC20TokenMock.new();
        //       let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
        //
        //       let adminContract_new = await TwoKeyAdmin.new(not_admin);
        //       let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
        //
        //       await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
        //       await exchange.send(1000);
        //
        //       let exchange_balance = await adminContract.getEtherBalanceOfAnAddress(exchange.address);
        //       let exchange_new_balance = await adminContract.getEtherBalanceOfAnAddress(exchange_new.address);
        //
        //       assert.notEqual(exchange_balance, 1000, "Exchange Balance should not be equal to 1000");
        //       assert.equal(exchange_balance, 0, "Exchange Balance should not be equal to 0");
        //       assert.equal(exchange_new_balance, 1000, "Exchange Balance should not be equal to 1000");
        // });
});

