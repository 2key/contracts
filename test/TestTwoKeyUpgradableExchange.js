
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
        const null_address = '0x0000000000000000000000000000000000000000';   


        before(async() => {
              erc20MockContract = await ERC20TokenMock.new();
              // adminContract = await TwoKeyAdmin.new(deployerAddress); 
            //  economyContract = await TwoKeyEconomy.new(adminContract.address);
        });


      it('Case 1 : TwokeyAdmin should be assigned as Admin Role for TwoKeyUpgradableExchange', async () => {

              let adminContract = await TwoKeyAdmin.new(deployerAddress); 
              let exchange =  await TwoKeyUpgradableExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);
              let isAdmin = await exchange.hasRole(adminContract.address, "admin");
              assert.equal(isAdmin, true, "should be the admin");
            
        });

        it('Case 2 : Any accont holder other than the TwoKeyUpgradableExchange should not be assigned as Admin Role for TwoKeyUpgradableExchange ', async () => {

              let adminContract =  await TwoKeyAdmin.new(deployerAddress);
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);
              let isAdmin = await exchange.hasRole(accounts[0], "admin");
              assert.notEqual(isAdmin, true, "should not be the admin");
        });

      
       it('Case 3 : Initial :: Null-Admin-TestCase', async () => {

            let adminContract = await TwoKeyAdmin.new(deployerAddress);
            await tryCatch(TwoKeyUpgradableExchange.new(1, null_address, erc20MockContract.address,adminContract.address), errTypes.anyError)
       });


      it('Case 4 : TwoKeyAdmin should have TwoKeyUpgradableExchange object', async () => {
        let adminContract = await TwoKeyAdmin.new(deployerAddress);
         let exchange =  await TwoKeyUpgradableExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);
          let exchangeFromAdmin= await adminContract.getTwoKeyUpgradableExchange();

          assert.equal(exchange.address, exchangeFromAdmin, 'TwoKeyAdmin should have two key exchange object');
      });  
      
 
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

      it('Case 6 : Sell Token negative Test Case  Should Give Error if Allowace not Approved', async () => {

              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              await exchange.send("1000000000");
              let initialBalance = await mockToken.balanceOf(accounts[0]);
              await tryCatch(exchange.sellTokens(), errTypes.anyError);
             
    });


    it('Case 7 : Sell Token negative Test Case  Should Give Error if Wallet Holder Does not have token balance', async () => {

              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              await exchange.send("1000000000");
              let initialBalance = await mockToken.balanceOf(accounts[0]);
              await tryCatch(exchange.sellTokens(), errTypes.anyError);
             
    });

    //  it('Case 8 : Sell Token negative Test Case  Should Give Error if Only Alive is False', async () => {
    //
    //           let adminContract = await TwoKeyAdmin.new(deployerAddress);
    //           let mockToken = await ERC20TokenMock.new(); //from: deployerAddress
    //           let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
    //           await exchange.send("1000000000");
    //           let initialBalance = await mockToken.balanceOf(accounts[0]);
    //
    //         adminContract_new = await TwoKeyAdmin.new(deployerAddress);
    //         economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
    //        // eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
    //         //regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
    //         exchangeContract_new =  await TwoKeyUpgradableExchange.new(1, deployerAddress, erc20MockContract.address, adminContract_new.address);
    //
    //       await adminContract.upgradeEconomyExchangeByAdmins(exchangeContract_new.address);
    //
    //           await tryCatch(exchange.sellTokens(), errTypes.anyError);
    //
    // });

   it('Case 9 : Sell Token negative Test Case  Should Give Error Wallet has less Wei than Token Price', async () => {

              let adminContract = await TwoKeyAdmin.new(deployerAddress);
              let mockToken = await ERC20TokenMock.new();
              let exchange = await TwoKeyUpgradableExchange.new(1, deployerAddress, mockToken.address,adminContract.address);
              let initialBalance = await mockToken.balanceOf(accounts[0]);
              await tryCatch(exchange.sellTokens(), errTypes.anyError);
             
    });
       
});

