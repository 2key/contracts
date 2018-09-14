
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyUpgradableExchange = artifacts.require("TwoKeyUpgradableExchange");
const ERC20TokenMock = artifacts.require('ERC20TokenMock');

const BigNumber = web3.BigNumber;

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
              let wallet = accounts[0];
              let adminAcc = accounts[1];
              let buyer = accounts[2];
              let adminContract = await TwoKeyAdmin.new(adminAcc);
              let mockToken = await ERC20TokenMock.new({from: wallet});                         // 1000000 - total supply - 10^6
              let exchange = await TwoKeyUpgradableExchange.new(1, wallet, mockToken.address,adminContract.address);
              
              // await exchange.send("1000000000");                                // 1000000000 - 10^9
              let initialBalance = await mockToken.balanceOf(wallet);      // 1000000 - 10^6 --- tokens

              console.log("Initial balance of wallet: " + initialBalance);
              // await mockToken.increaseApproval(buyer,500);
              //
              // let allowed = await mockToken.allowance(wallet,buyer);
              // console.log("Buyer is allowed to spend : " + allowed);
              //
              // let trnx = await exchange.buyTokens(buyer, {value: 1, from:wallet});                          //contractInstance.methods.mymethod(param).send({from:account, value:wei})

              await exchange.sendTransaction({from: buyer, value: 100});
              let bal = await mockToken.balanceOf(buyer);
              console.log("Balance of buyer is : " + bal);
              console.log("Wallet address: " + wallet);
              console.log("Admin acc address:" + adminAcc);
              console.log("Buyer address: " + buyer);

              console.log("Token contract : " + mockToken.address);
                // console.log(trnx.logs[0].args);
              // // await exchange.buyTokens(accounts[0]).send({value:100000});                       //contractInstance.methods.mymethod(param).send({from: address, value: web3.utils.toWei( value, 'ether')})
              //
              // let initialBalanceAfter = await mockToken.balanceOf(accounts[0]);      // 1000000 - 10^6 --- tokens
              //
              // //let tokens = await mockToken.balanceOf(accounts[0]);
              // //await exchange.sellTokens(10000);
              //
              // let weiRaised = await exchange.getWeiRaised();
              // //let amt = await exchange.getAmount();                             // 10000 - 10^4
              // //let leftOverBalance = await mockToken.balanceOf(accounts[0]);     // 1000000 - 10^6
              // //let expected = initialBalance - sellTokens;
              // await exchange.setValuess();                    // 999000
              // let token = await exchange.getTokenVall();
              // let value = await exchange.getValueVall();
              // let to = await exchange.getToVall();
              //
              // assert.equal(true, false,"\n to: "+to+"\nValue: "+value+"\n Token: "+token+"\n initialBalance: "+initialBalance+"\n initialBalanceAfter: "+initialBalanceAfter+"\nweiRaised: "+weiRaised);
              // assert.equal(true, false,"\nweiRaised: "+weiRaised+ "\n sellTokens: "+sellTokens+ "\namt: "+amt+"\n leftOverBalance: " + leftOverBalance + "\n expected: " + expected);
              // assert.equal(leftOverBalance, expected,  'After sellTokens remaining balance should be :' + leftOverBalance);
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

        /// Upgrade Exchange should set filler with value when in alive state
        it('Case 10 : Upgrade Exchange Test Case Should set filler with value when Alive', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              
              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
              
              await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
              let filler = await exchange.getFiller();
              assert.equal(filler, exchange_new.address, "filler should be equal to "+ exchange_new.address);
        });

        /// Upgrade Exchange Test Case Should give error when not Alive
        it('Case 11 : Upgrade Exchange Test Case Should give error when not Alive', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              
              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);

              await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
              await tryCatch(adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address), errTypes.anyError);
        });

        // /// should check in sol that the address is of type exchange ! 
        // it('Case 12 : Upgrade Exchange Test Case Should give error when not Alive', async () => {

        //           let adminContract = await TwoKeyAdmin.new(deployerAddress);
        //           let mockToken = await ERC20TokenMock.new();
        //           let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
                  
        //           await tryCatch(exchange.upgrade(deployerAddress), errTypes.anyError);
        // });


        /// Upgradable Exchange should not give error when called by admin
        it('Case 13 : Upgrade Exchange Test Case Should not give error when called by admin', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              
              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
              
              await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
              let filler = await exchange.getFiller();
              assert.equal(filler, exchange_new.address, "filler should be equal to "+ exchange_new.address);
        });

        /// Upgradable Exchange should give error when called by non admin
        it('Case 14 : Upgrade Exchange Test Case Should give error when called by non admin', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              
              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
              
              await tryCatch(exchange.upgrade(exchange_new.address), errTypes.anyError);
        });

        /// Fallback payable method when alive should add payable amount to exchange contract balance
        it('Case 15 : Fallback payable method when alive should add payable amount to exchange contract balance', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              
              await exchange.send(1000);
              let balance = await adminContract.getEtherBalanceOfAnAddress(exchange.address);
              assert.equal(balance, 1000, "Exchange Balance should be equal to 1000");
        });

        /// Fallback payable method when not alive should add payable amount to new exchange contract
        it('Case 16 : Fallback payable method when not alive should add payable amount to new exchange contract', async () => {
              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              
              let adminContract_new = await TwoKeyAdmin.new(not_admin);
              let exchange_new = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract_new.address);
             
              await adminContract.upgradeEconomyExchangeByAdmins(exchange_new.address);
              await exchange.send(1000);

              let exchange_balance = await adminContract.getEtherBalanceOfAnAddress(exchange.address);
              let exchange_new_balance = await adminContract.getEtherBalanceOfAnAddress(exchange_new.address);

              assert.notEqual(exchange_balance, 1000, "Exchange Balance should not be equal to 1000");
              assert.equal(exchange_balance, 0, "Exchange Balance should not be equal to 0");
              assert.equal(exchange_new_balance, 1000, "Exchange Balance should not be equal to 1000");
        });   
});

