const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyExchange = artifacts.require("TwoKeyUpgradableExchange");
const TwoKeyReg = artifacts.require('TwoKeyReg');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
//const ethers = require("./utils");

contract('TwoKeyAdmin', async (accounts) => {
  let tryCatch = require("./exceptions.js").tryCatch;
  let errTypes = require("./exceptions.js").errTypes;

    let adminContract;
    let exchangeContract;
    let economyContract;
    let regContract;
    let eventContract;
    let deployerAddress = accounts[0]; // '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
    let not_admin = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b'; 
    let acc2 = '0x95ced938f7991cd0dfcb48f0a06a40fa1af46ebc';
    let moderator_addr = '0x3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9'; 
              
    const null_address = '0x0000000000000000000000000000000000000000';   
    const BigNumber = web3.BigNumber;

      
        //============================================================================================================
        // TEST CASES FOR INITIAL

        /// Test Case: Passing null_address as ElectorateAdmins Address should revert
        it('Case 1 : Initial :: Null-ElectorateAdmins-Address-TestCase', async () => {
              await tryCatch(TwoKeyAdmin.new(null_address), errTypes.anyError); 
        });

        /// Test Case: Passing non null addresses in all three should not revert
        it('Case 2 : Initial :: Non-Null-Parameters-TestCase', async () => {
              await TwoKeyAdmin.new(deployerAddress);
        });

        //============================================================================================================
        // TEST CASES FOR REPLACE

        /// Test Case: Passing null address as admincontract address should revert
        it('Case 3 : Replace :: Passing-Null-Address-TestCase', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              await tryCatch(adminContract.replaceOneself(null_address), errTypes.anyError); // null address check is required in sol ! (here error is catched due to revert thrown by transfer)
        });


        /// Test Case: Passing admincontract address which is already replaced once should revert
        it('Case 4 : Replace :: Already-Replaced-AdminContract-TestCase', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address);

              await adminContract.replaceOneself(adminContract_new.address);  
              await tryCatch(adminContract.replaceOneself(adminContract_new.address), errTypes.anyError);  
        });


        /// Test Case: Passing admincontract address which is not admin Voting Approved should revert
        it('Case 5 : Replace :: Address-Not-Approved-By-Admin-TestCase', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);
              
              adminContract_new = await TwoKeyAdmin.new(not_admin);
              economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
              eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
              regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
              exchangeContract_new =  await TwoKeyExchange.new(1, deployerAddress, economyContract_new.address,adminContract_new.address);
              await adminContract_new.setSingletones(economyContract_new.address, exchangeContract_new.address, regContract_new.address, eventContract_new.address);

              await tryCatch(adminContract_new.replaceOneself(adminContract.address), errTypes.anyError);  
        });

        /// Positive scenarios where Replace should work
        it('Case 6 : Replace', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address);
              
              const adminContract_balance1 = await economyContract.balanceOf(adminContract.address);
              const adminContract_balance1_string = JSON.stringify(adminContract_balance1);

              await adminContract.replaceOneself(adminContract_new.address);

              const adminContract_new_balance = await economyContract.balanceOf(adminContract_new.address);
              const adminContract_new_balance_string = JSON.stringify(adminContract_new_balance); 

              const adminContract_balance2 = await economyContract.balanceOf(adminContract.address);
              const adminContract_balance2_string = JSON.stringify(adminContract_balance2); 

              assert.equal(adminContract_balance1.c[0], adminContract_new_balance.c[0], "New Admin should have 1e+24 tokens");
        });

        /// To verify if TwoKeyEconomy is set to new_admin
        it('Case 7 : To verify if TwoKeyEconomy is set to new_admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  = await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address);

              await adminContract.replaceOneself(adminContract_new.address); 

              let economyObj = await adminContract_new.getTwoKeyEconomy();
              assert.equal(economyContract.address, economyObj, "TwoKeyReg Addresses should match");
        });

        /// To verify if TwoKeyReg is set to new_admin
        it('Case 8 : To verify if TwoKeyReg is set to new_admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  = await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address);
              await adminContract.replaceOneself(adminContract_new.address); 
              
              let regObj = await adminContract_new.getTwoKeyReg();
              assert.equal(regContract.address, regObj, "TwoKeyReg Addresses should match"); 
        });

        // ===================================================================================
        // TEST CASES FOR transferByAdmin

        /// Passing null address to transferByAdmin method should give an error
        it('Case 9 : transferByAdmins-null-address', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              tokens = new BigNumber(100);
              await tryCatch(adminContract.transferByAdmins(null_address, tokens), errTypes.anyError); 
        });

        /// Passing null value to transferByAdmin method should give an error
        it('Case 10 : transferByAdmins-null-value', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              tokens = new BigNumber(0);
              await tryCatch(adminContract.transferByAdmins(deployerAddress, 0), errTypes.anyError); 
        });
      
        /// Should give an error if adminContract is already replaced
        it('Case 11 : transferByAdmins-adminContract-already-replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  = await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address);

              await adminContract.replaceOneself(adminContract_new.address);
              await tryCatch(adminContract.transferByAdmins(deployerAddress, 1000), errTypes.anyError);
        });
        
        /// Should give an error if method is called by an address not approved by admin
        it('Case 12 : transferByAdmins-adminContract-not-approved-by-admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(not_admin);
              economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
              eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
              regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
              exchangeContract_new =  await TwoKeyExchange.new(1, deployerAddress, economyContract_new.address, adminContract_new.address);
              await adminContract_new.setSingletones(economyContract_new.address, exchangeContract_new.address, regContract_new.address, eventContract_new.address);
          
              await tryCatch(adminContract_new.transferByAdmins(deployerAddress, 100), errTypes.anyError); // revert is due to incorrect params
        });

        /// Positive scenario for transferByAdmin method
        it('Case 13 : transferByAdmins', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              address = not_admin;
              await adminContract.transferByAdmins(address, 1000);
              let not_admin_balance = await economyContract.balanceOf(not_admin);
              assert.equal(not_admin_balance, 1000, "new address should have 1000 tokens in balance");
        });

        // ========================================================================
        // TEST CASES for Upgradable Exchange Method 

        /// Positive Scenario for upgradeEconomyExchangeByAdmins method
        it('Case 14 : upgradeEconomyExchangeByAdmins', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
              eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
              regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
              exchangeContract_new =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract_new.address);
              await adminContract_new.setSingletones(economyContract_new.address, exchangeContract_new.address, regContract_new.address, eventContract_new.address);

              await adminContract.upgradeEconomyExchangeByAdmins(exchangeContract_new.address);   
        });

        /// Should give an error when null address is passed in upgradeEconomyExchangeByAdmins method
        it('Case 15 : upgradeEconomyExchangeByAdmins-null-address', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              await tryCatch(adminContract.upgradeEconomyExchangeByAdmins(null_address), errTypes.anyError);
        });

        /// Should give an error if adminContract is already replaced
        it('Case 16 : upgradeEconomyExchangeByAdmins-already-replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address);
              await adminContract.replaceOneself(adminContract_new.address);
        
              exchangeContract_new =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract_new.address);
              await tryCatch(adminContract.upgradeEconomyExchangeByAdmins(exchangeContract_new.address), errTypes.anyError);
        });

        /// Should give an error if method is called by an address not approved by admin
        it('Case 17 : upgradeEconomyExchangeByAdmins-not-approved-by-admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(not_admin);
              economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
              eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
              regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
              exchangeContract_new =  await TwoKeyExchange.new(1, not_admin, economyContract.address, adminContract_new.address);
              await adminContract_new.setSingletones(economyContract_new.address, exchangeContract_new.address, regContract_new.address, eventContract_new.address);

              await tryCatch(adminContract_new.upgradeEconomyExchangeByAdmins(exchangeContract_new.address), errTypes.anyError);
        });

        //===================================================================================================
        // TEST CASES for Transfer Ethers By Admin Method

        /// Positive scenario for transferEtherByAdmins method
        it('Case 18 : transferEtherByAdmins', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);
        
              let address = not_admin;
              let amount = 10000;

              bal_before = new BigNumber(0);
              bal_before = await adminContract.getEtherBalanceOfAnAddress(address);
              await adminContract.send("100000000");
              await adminContract.transferEtherByAdmins(address, amount);
              bal_after = new BigNumber(0);
              bal_after = await adminContract.getEtherBalanceOfAnAddress(address);

              let increment = bal_after.sub(bal_before);
              assert.equal(increment.c[0], 10000, "An increment in ether should be 100");
        });
      
        /// Should give an error when null address is passed
        it('Case 19 : transferEtherByAdmins - null address', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              const ethers = 10;
              await tryCatch(adminContract.transferEtherByAdmins(null_address, ethers), errTypes.anyError);
        });

        /// Should give an error when null value is passed
        it('Case 20 : transferEtherByAdmins - null value', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              let address = not_admin;
       
              const ethers = 0;
              await tryCatch(adminContract.transferEtherByAdmins(deployerAddress, ethers), errTypes.anyError);
        });

        /// Should give an error if adminContract is already replaced
        it('Case 21 : transferEtherByAdmins - already - replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);
              
              adminContract_new = await TwoKeyAdmin.new(deployerAddress);

              await adminContract_new.addPreviousAdmin(adminContract.address);
              await adminContract.replaceOneself(adminContract_new.address);
              address = not_admin; 
              const ethers = 1000; 
              await tryCatch(adminContract.transferEtherByAdmins(address, ethers),errTypes.anyError); // TODO: solve param issue
        });

        /// Should give an error if method is called by an address not approved by admin
        it('Case 22 : transferEtherByAdmins -not-approved-by-admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              adminContract_new = await TwoKeyAdmin.new(not_admin);
              economyContract_new = await TwoKeyEconomy.new(adminContract_new.address);
              eventContract_new  =await TwoKeyEventSource.new(adminContract_new.address);
              regContract_new = await TwoKeyReg.new(eventContract_new.address, adminContract_new.address);
              exchangeContract_new =  await TwoKeyExchange.new(1, not_admin, economyContract.address, adminContract_new.address);
              await adminContract_new.setSingletones(economyContract_new.address, exchangeContract_new.address, regContract_new.address, eventContract_new.address);

              let address = not_admin; 
              const ethers = 1000; 
              await tryCatch(adminContract_new.transferEtherByAdmins(address, ethers), errTypes.anyError); // param issue
        });
       
        // ==================================================================================================

        /// Payable value will be added to the existing contract when not replaced 
        it('Case 23 : payable-function when not replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              await adminContract.send("1000");
              let bal = await adminContract.getEtherBalanceOfAnAddress(adminContract.address);
              assert.equal(bal, 1000, "Admin Contract ether balance should be equal to 100");
        });

        /// Payable value will be added to the new admin contract when replaced 
        it('Case 24 : payable-function when replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);
           
              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address);
              await adminContract.replaceOneself(adminContract_new.address);
              await adminContract.send("1000");

              let bal = await adminContract.getEtherBalanceOfAnAddress(adminContract.address);
              let bal2 = await adminContract_new.getEtherBalanceOfAnAddress(adminContract_new.address);

              assert.equal(bal, 0, "Old Admin Address should have 0 ethers");
              assert.equal(bal2, 1000, "New Admin Address should have 1000 ethers");
        });

        /// Destroy method when admin not replaced
        it('Case 25: destroy-function when admin not replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);
         
              const deployerAddressBal1 = await adminContract.getEtherBalanceOfAnAddress(deployerAddress);  // 0
              await adminContract.send("10000");
              const adminBal = await adminContract.getEtherBalanceOfAnAddress(adminContract.address); // 10000

              await adminContract.destroy();
              let admin_bal = await adminContract.getEtherBalanceOfAnAddress(adminContract.address); // 0
            
              assert.equal(adminBal, 10000, "Admin contract should have 10000 ethers before destroyed");
              assert.equal(admin_bal, 0, "Admin contract should have 0 ethers after destroyed");
        });

        // ==========================================================================================================

        /// Positive scenario
        it('Case 26 : Add Moderator Positive', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);
         
              let moderator_addr = '0x3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9'; 
              await adminContract.addModeratorForReg(moderator_addr, {from: deployerAddress});

              let moderator = await regContract.getModeratorRole();

              let test_moderator = await regContract.hasRole(moderator_addr, moderator);
              assert.equal(test_moderator, true, "Moderator not added!"); 
        });

        /// When already replaced
        it('Case 27 : Should not Add Moderator by admin when Admin already replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);
           
              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address, {from: deployerAddress});
              await adminContract.replaceOneself(adminContract_new.address, {from: deployerAddress});

              await tryCatch(adminContract.addModeratorForReg(moderator_addr, {from: deployerAddress}), errTypes.anyError);
        });

        /// when not approved by admin
        it('Case 28 : Should not add Moderator when caller is not approved by admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              await tryCatch(adminContract.addModeratorForReg(moderator_addr, {from: not_admin}), errTypes.anyError);

        });

        /// Remove Moderator Role by Admin - positive scenario
        it('Case 29 : Remove Moderator Role by Admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress);
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventContract  =await TwoKeyEventSource.new(adminContract.address);
              regContract = await TwoKeyReg.new(eventContract.address, adminContract.address);
              exchangeContract =  await TwoKeyExchange.new(1, deployerAddress, economyContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address, exchangeContract.address, regContract.address, eventContract.address);

              let moderator = await regContract.getModeratorRole();

              await adminContract.addModeratorForReg(moderator_addr, {from: deployerAddress});
              let test_moderator = await regContract.hasRole(moderator_addr, moderator);
              assert.equal(test_moderator, true, "Moderator did not matched!");
              
              await adminContract.removeModeratorForReg(moderator_addr, {from: deployerAddress});
              test_moderator = await regContract.hasRole(moderator_addr, moderator);
              assert.notEqual(test_moderator, moderator_addr, "Moderator should not matched!");
        });

        /// when already replaced
        it('Case 30 : Should not remove Moderator Role by Admin when admin is already replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress); 
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
              exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);

              let moderator = await regContract.getModeratorRole();

              await adminContract.addModeratorForReg(moderator_addr, {from: deployerAddress});
              let test_moderator = await regContract.hasRole(moderator_addr, moderator);
              assert.equal(test_moderator, true, "Moderator did not matched!");
              
              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address, {from:deployerAddress});
              await adminContract.replaceOneself(adminContract_new.address, {from: deployerAddress});

              await tryCatch(adminContract.removeModeratorForReg(moderator_addr, {from: deployerAddress}), errTypes.anyError);       
        });

        /// when not approved by admin
        it('Case 31 : Should not remove moderator Role when caller is not approved by admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress); 
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
              exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
         
              let moderator = await regContract.getModeratorRole();

              await adminContract.addModeratorForReg(moderator_addr, {from: deployerAddress});
              let test_moderator = await regContract.hasRole(moderator_addr, moderator);
              assert.equal(test_moderator, true, "Moderator did not matched!");
              
              await tryCatch(adminContract.removeModeratorForReg(moderator_addr, {from: not_admin}), errTypes.anyError);       
        });

        /// positive scenario
        it('Case 32 : Update Moderator Role by Admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress); 
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
              exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);

              let moderator = await regContract.getModeratorRole();
              
              await adminContract.addModeratorForReg(moderator_addr, {from: deployerAddress});
              let test_moderator = await regContract.hasRole(moderator_addr, moderator);
              assert.equal(test_moderator, true, "Moderator did not matched!");
              
              await adminContract.updateModeratorForReg(moderator_addr, acc2, {from: deployerAddress});
              test_moderator = await regContract.hasRole(acc2, moderator);
              assert.equal(test_moderator, true, "Moderator did not matched!");
        });

        /// when already replaced
        it('Case 33 : Should not update moderator role by Admin when admin is already replaced', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress); 
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
              exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);

              let moderator = await regContract.getModeratorRole();

              await adminContract.addModeratorForReg(moderator_addr, {from: deployerAddress});
              let test_moderator = await regContract.hasRole(moderator_addr, moderator);
              assert.equal(test_moderator, true, "Moderator did not matched!");
              
              adminContract_new = await TwoKeyAdmin.new(deployerAddress);
              await adminContract_new.addPreviousAdmin(adminContract.address, {from: deployerAddress});
              await adminContract.replaceOneself(adminContract_new.address, {from: deployerAddress});
              
              await tryCatch(adminContract.updateModeratorForReg(moderator_addr, acc2, {from: deployerAddress}), errTypes.anyError);
        });

        /// when not approved by admin
        it('Case 34 : Should not Update Moderator Role if caller is not approved by admin', async () => {
              adminContract = await TwoKeyAdmin.new(deployerAddress); 
              economyContract = await TwoKeyEconomy.new(adminContract.address);
              eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
              exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
              let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
              await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);

              let moderator = await regContract.getModeratorRole();
              
              await adminContract.addModeratorForReg(moderator_addr, {from: deployerAddress});
              let test_moderator = await regContract.hasRole(moderator_addr, moderator);
              assert.equal(test_moderator, true, "Moderator did not matched!");
              
              await tryCatch(adminContract.updateModeratorForReg(moderator_addr, acc2, {from: not_admin}), errTypes.anyError);
        });

});