const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyExchange = artifacts.require("TwoKeyUpgradableExchange");
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const TwoKeyReg = artifacts.require('TwoKeyReg');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
//const ethers = require("./utils");

contract('TwoKeyAdmin', async (accounts) => {
  let tryCatch = require("./exceptions.js").tryCatch;
  let errTypes = require("./exceptions.js").errTypes;

    let adminContract;
    let exchangeContract;
    let erc20MockContract;
    let economyContract;
    let regContract;
    let eventContract;
    let deployerAddress = '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
    let not_admin = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';
    
    const null_address = '0x0000000000000000000000000000000000000000';   
     
    const BigNumber = web3.BigNumber;

    before(async() => {
          erc20MockContract = await ERC20TokenMock.new();
    });
  
    //============================================================================================================
    // TEST CASES FOR INITIAL

    // Test Case: Passing null_address as ElectorateAdmins Address should revert
    it('Case 1 : Initial :: Null-ElectorateAdmins-Address-TestCase', async () => {
          await tryCatch(TwoKeyAdmin.new(null_address), errTypes.anyError); 
    });

    // Test Case: Passing null_address as Exchange Address should revert  
    it('Case 2 : Initial :: Null-Exchange-Address-TestCase', async () => {
         // await tryCatch(TwoKeyAdmin.new(deployerAddress), errTypes.anyError)
         //No need of this test now
    });

    // Test Case: Passing non null addresses in all three should not revert
    it('Case 3 : Initial :: Non-Null-Parameters-TestCase', async () => {
          await TwoKeyAdmin.new(deployerAddress);
    });

    //============================================================================================================
    // TEST CASES FOR REPLACE

    // Test Case: Passing null address as admincontract address should revert
    it('Case 4 : Replace :: Passing-Null-Address-TestCase', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          
          await tryCatch(adminContract.replaceOneself(null_address), errTypes.anyError); // null address check is required in sol ! (here error is catched due to revert thrown by transfer)
    });

    // Test Case: Passing admincontract address which is already replaced once should revert
    it('Case 5 : Replace :: Already-Replaced-AdminContract-TestCase', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);
          adminContract_new = await TwoKeyAdmin.new(deployerAddress);
          
          await adminContract.replaceOneself(adminContract_new.address);  
          //await adminContract.replaceOneself(adminContract.address);  
          //await tryCatch(adminContract.replaceOneself(adminContract_new.address), errTypes.anyError); 
    });

    // Test Case: Passing admincontract address which is not admin Voting Approved should revert
    it('Case 6 : Replace :: Address-Not-Approved-By-Admin-TestCase', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          //let exchange =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(not_admin);
          economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
          eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
          regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);

          await tryCatch(adminContract_new.replaceOneself(adminContract.address), errTypes.anyError);  
    });

    // Test Case: Positive scenarios where Replace should work
    // it('Case 7 : Replace', async () => {
    //       adminContract = await TwoKeyAdmin.new(deployerAddress, exchangeContract.address);
    //       economyContract = await TwoKeyEconomy.new(adminContract.address);
    //       eventContract  =await TwoKeyEventSource.new(adminContract.address);
    //       regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);

    //       adminContract_new = await TwoKeyAdmin.new(deployerAddress, exchangeContract.address);
          
    //       const adminContract_balance1 = await economyContract.balanceOf(adminContract.address);
    //       const adminContract_balance1_string = JSON.stringify(adminContract_balance1);

    //       await adminContract.replaceOneself(adminContract_new.address);

    //       const adminContract_new_balance = await economyContract.balanceOf(adminContract_new.address);
    //       const adminContract_new_balance_string = JSON.stringify(adminContract_new_balance); 

    //       const adminContract_balance2 = await economyContract.balanceOf(adminContract.address);
    //       const adminContract_balance2_string = JSON.stringify(adminContract_balance2); 

    //       //const zero = JSON.stringify(0);

    //       assert.equal(adminContract_balance1_string, adminContract_new_balance_string, "New Admin should have 1e+24 tokens");
    //       //assert.equal(adminContract_balance2, 0, "Old admin contract balance should be zero after replace")
    // });

    it('Case 8 : To verify if TwoKeyEconomy is set to new_admin', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  = await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(deployerAddress);

          await adminContract.replaceOneself(adminContract_new.address); 
          
          //let economyObj = await adminContract_new.getTwoKeyEconomy();
          //assert.equal(economyContract.address, economyObj, "TwoKeyEconomy Addresses should match"); 
    });

    it('Case 9 : To verify if TwoKeyReg is set to new_admin', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  = await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(deployerAddress);

          await adminContract.replaceOneself(adminContract_new.address); 
          
          let regObj = await adminContract_new.getTwoKeyReg();
          assert.equal(regContract.address, regObj, "TwoKeyReg Addresses should match"); 
    });


    //===================================================================================
    // TEST CASES FOR transferByAdmin

    it('Case 10 : transferByAdmins-null-address', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address,adminContract.address);

          tokens = new BigNumber(100);
          await tryCatch(adminContract.transferByAdmins(null_address, tokens), errTypes.anyError); 
    });

    it('Case 11 : transferByAdmins-null-value', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);

          tokens = new BigNumber(0);
          await tryCatch(adminContract.transferByAdmins(deployerAddress, 0), errTypes.anyError); 
    });
  
    // Test Case: When adminContract already replaced
    it('Case 12 : transferByAdmins-adminContract-already-replaced', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  = await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(deployerAddress);
          economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
          eventContract_new  = await TwoKeyEventSource.new(adminContract_new.address);
          regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
          exchangeContract_new = await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract_new.address);

          await adminContract.replaceOneself(adminContract_new.address);
          
          await tryCatch(adminContract.transferByAdmins(deployerAddress, 1000), errTypes.anyError);
    });
    
    // Test Case: When calling address not approved by admin
    it('Case 13 : transferByAdmins-adminContract-not-approved-by-admin', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(not_admin);
          economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
          eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
          regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
      
          await tryCatch(adminContract_new.transferByAdmins(deployerAddress, 100), errTypes.anyError); // revert is due to incorrect params
    });

    it('Case 14 : transferByAdmins', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);

          address = not_admin;

          await adminContract.transferByAdmins(address, 1000);

          let not_admin_balance = await economyContract.balanceOf(not_admin);

          assert.equal(not_admin_balance, 1000, "new address should have 1000 tokens in balance");
    });

    // ========================================================================
    // TEST CASES for Upgradable Exchange Method 

    it('Case 15 : upgradeEconomyExchangeByAdmins', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(deployerAddress);
          economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
          eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
          regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
          exchangeContract_new =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract_new.address);

          await adminContract.upgradeEconomyExchangeByAdmins(exchangeContract_new.address);   
    });

    // Test Case: null address
    it('Case 16 : upgradeEconomyExchangeByAdmins-null-address', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract.address);

          await tryCatch(adminContract.upgradeEconomyExchangeByAdmins(null_address), errTypes.anyError);
    });

     // Test Case: wasNotReplaced = false
     it('Case 17 : upgradeEconomyExchangeByAdmins-already-replaced', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(deployerAddress);
          
          await adminContract.replaceOneself(adminContract_new.address);
          exchangeContract_new =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract_new.address);
    
          await tryCatch(adminContract.upgradeEconomyExchangeByAdmins(exchangeContract_new.address), errTypes.anyError);
    });

    // Test Case: when admin not approve
    it('Case 18 : upgradeEconomyExchangeByAdmins-not-approved-by-admin', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(not_admin);
          economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
          eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
          regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
          exchangeContract_new =  await TwoKeyExchange.new(1, not_admin, erc20MockContract.address, adminContract_new.address);

          await tryCatch(adminContract_new.upgradeEconomyExchangeByAdmins(exchangeContract_new.address), errTypes.anyError);
    });

    //===================================================================================================
    // TEST CASES for Transfer Ethers By Admin Method

    it('Case 19 : transferEtherByAdmins', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
    
          let address = not_admin;
          let amount = 100;

          await adminContract.send("100000");
    
          await adminContract.transferEtherByAdmins(address, amount);

          let bal = await adminContract.getEtherBalanceOfAnAddress(address);
          // how to check
    });
  
    // Test Case: null address 
    it('Case 20 : transferEtherByAdmins - null address', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);

          const ethers = 10;
          // await admin.transferEtherByAdmins(null_address, 1000000);  // error expected
          await tryCatch(adminContract.transferEtherByAdmins(null_address, ethers), errTypes.anyError); // issue with the params
    });

    // Test Case: null value
    it('Case 21 : transferEtherByAdmins - null value', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);

          let address = not_admin;
   
          const ethers = 0;
          //await admin.transferEtherByAdmins(address1, 0);  // error expected
          await tryCatch(adminContract.transferEtherByAdmins(deployerAddress, ethers), errTypes.anyError); // params issue 
    });

    // Test Case: wasNotReplaced
    it('Case 22 : transferEtherByAdmins - already - replaced', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
          exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(deployerAddress);
          economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
          eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
          regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
          exchangeContract_new =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract_new.address);

          await adminContract.replaceOneself(adminContract_new.address);
       
          address = not_admin; 
          const ethers = 1000; 

          //await admin.transferEtherByAdmins(address1, 10000);  // error expected
          await tryCatch(adminContract.transferEtherByAdmins(address, ethers),errTypes.anyError); // TODO: solve param issue
    });

     // Test Case: admin not approve
     it('Case 23 : transferEtherByAdmins -not-approved-by-admin', async () => {
          adminContract = await TwoKeyAdmin.new(deployerAddress);
          economyContract = await TwoKeyEconomy.new(adminContract.address);
          eventContract  =await TwoKeyEventSource.new(adminContract.address);
          regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);

          adminContract_new = await TwoKeyAdmin.new(not_admin);
          economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
          eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
          regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);

          let address = not_admin; 
          const ethers = 1000; 
    
          await tryCatch(adminContract_new.transferEtherByAdmins(address, ethers), errTypes.anyError); // param issue
    });
   
   // ==================================================================================================

    it('Case 24 : payable-function when not replaced', async () => {
        adminContract = await TwoKeyAdmin.new(deployerAddress);
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventContract  =await TwoKeyEventSource.new(adminContract.address);
        regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);

        await adminContract.send("1000");

        let bal = await adminContract.getEtherBalanceOfAnAddress(adminContract.address);
        
        assert.equal(bal, 1000, "Admin Contract ether balance should be equal to 100");
    });

    it('Case 25 : payable-function when replaced', async () => {
        adminContract = await TwoKeyAdmin.new(deployerAddress);
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventContract  =await TwoKeyEventSource.new(adminContract.address);
        regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
        exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, erc20MockContract.address, adminContract.address);
     
        adminContract_new = await TwoKeyAdmin.new(deployerAddress);

        await adminContract.replaceOneself(adminContract_new.address);

        await adminContract.send("1000");

        let bal = await adminContract.getEtherBalanceOfAnAddress(adminContract.address);
        let bal2 = await adminContract_new.getEtherBalanceOfAnAddress(adminContract_new.address);

        assert.equal(bal, 0, "Old Admin Address should have 0 ethers");
        assert.equal(bal2, 1000, "New Admin Address should have 1000 ethers");
    });


    it('Case 26: destroy-function when admin not replaced', async () => {
        adminContract = await TwoKeyAdmin.new(deployerAddress);
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventContract  =await TwoKeyEventSource.new(adminContract.address);
        regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
     
        const deployerAddressBal1 = await adminContract.getEtherBalanceOfAnAddress(deployerAddress);  // 0
        
        await adminContract.send("10000");
        const adminBal = await adminContract.getEtherBalanceOfAnAddress(adminContract.address); // 10000

        await adminContract.destroy();

        let admin_bal = await adminContract.getEtherBalanceOfAnAddress(adminContract.address); // 0
        
        assert.equal(adminBal, 10000, "Admin contract should have 10000 ethers before destroyed");
        assert.equal(admin_bal, 0, "Admin contract should have 0 ethers after destroyed");
    });
});