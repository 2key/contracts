const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyExchange = artifacts.require("TwoKeyUpgradableExchange");

contract('TwoKeyAdmin', async (accounts) => {
  let tryCatch = require("./exceptions.js").tryCatch;
  let errTypes = require("./exceptions.js").errTypes;
  
  let electorateAdmins_address = accounts[0];
  let wallet = accounts[0];
  let rate = 1;

  const null_address = '0x0000000000000000000000000000000000000000';

  //============================================================================================================
  // TEST CASES FOR INITIAL

  // Test Case: Passing null_address as Economy Address should revert
  it('Initial :: Null-Economy-Address-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;
    
    await tryCatch(TwoKeyAdmin.new(null_address, electorateAdmins_address, exchange_address), errTypes.revert);
  });

  // Test Case: Passing null_address as ElectorateAdmins Address should revert  
  it('Initial :: Null-ElectorateAdmins-Address-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    await tryCatch(TwoKeyAdmin.new(economy_address, null_address, exchange_address), errTypes.revert);  
  });

  // Test Case: Passing null_address as Exchange Address should revert  
  it('Initial :: Null-Exchange-Address-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    await tryCatch(TwoKeyAdmin.new(economy_address, electorateAdmins_address, null_address), errTypes.revert);
  });

  // Test Case: Passing non null addresses in all three should not revert
  it('Initial :: Non-Null-Parameters-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
  });
  //============================================================================================================
  // TEST CASES FOR REPLACE

  // Test Case: Passing null address as admincontract address should revert
  it('Replace :: Passing-Null-Address-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    
    await tryCatch(admin.replaceOneself(null_address), errTypes.revert); // null address check is required in sol ! (here error is catched due to revert thrown by transfer)
  });

  // Test Case: Passing admincontract address which is already replaced once should revert
  it('Replace :: Already-Replaced-AdminContract-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    
    await admin.replaceOneself(admin.address);  
    await tryCatch(admin.replaceOneself(admin.address), errTypes.revert); 
  });

  // Test Case: Passing admincontract address which is not admin Voting Approved should revert
  it('Replace :: Address-Not-Approved-By-Admin-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    electorateAdmins_address = accounts[2];
    let not_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    await tryCatch(not_admin.replaceOneself(admin.address), errTypes.revert);  
  });


/*  it('Replace', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    let new_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    let adminContract_balance = await web3.eth.getBalance(admin.address);

    await admin.replaceOneself(new_admin.address);
   
    // let sender = await admin.getAddress.call();
    // let owner = await admin.getOwnerAddress.call();
    // assert.equal(true,false, sender+'------------------------------'+owner);

    let adminContract_new_balance = await web3.eth.getBalance(admin.address);
    //assert.equal(true,false, 'admin address = '+ adminContract_balance+ ' ===========> '+ adminContract_new_balance); 
    assert.equal(adminContract_balance, adminContract_new_balance, ' Message');     // balances are 0 still assertion fails    
  });
*/
  //===================================================================================
  // TEST CASES FOR transferByAdmin

  it('transferByAdmins-null-address', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
  
  //  await admin.transferByAdmins(null_address, 1000000);   // null address check is reuired in sol !
    await tryCatch(admin.transferByAdmins(null_address, 1000000), errTypes.revert); // error is catched due to transfer or parameters are not passed correctly
});

 /* it('transferByAdmins-null-value', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;

    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
  
//    await admin.transferByAdmins(wallet, 10);   // null value check is reuired in sol !
    await tryCatch(admin.transferByAdmins(wallet, 0), errTypes.revert);   // error is catched due to transfer or parameters are not passed correctly
  });
  */
  // Test Case: When adminContract already replaced
/*  it('transferByAdmins-adminContract-already-replaced', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    let new_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    await admin.replaceOneself(new_admin);

    //await admin.transferByAdmins(wallet, 1000000 );   // expected error -- add tryCatch
    await tryCatch(admin.transferByAdmins(wallet, 1000000),errTypes.revert); // revert is due to incorrect parameters
  });
/    
  // Test Case: When calling address not approved by admin
/*  it('transferByAdmins-adminContract-already-replaced', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    electorateAdmins_address = accounts[2];
    let not_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

  //  await not_admin.transferByAdmins(wallet, 1000000 );   // expected error -- add tryCatch
    await tryCatch(not_admin.transferByAdmins(wallet, 1000000 ), errTypes.revert); // revert is due to incorrect params
  });
*/
  it('transferByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;

    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    let address = accounts[2];
    //let tokens = 1;

    //let balance = await admin.getBalances(address);
    //assert.equal(true, false, "==============================>" + balance);
    await admin.transferByAdmins(address, 1);

    // let address_balance = web3.eth.getBalance(address);
    // let address_balance = economyObj.getBalances(wallet);
    // assert.equal(true, false, 'address balance ========> '+ address_balance);
  });

  
  // ========================================================================
/*  it('upgradeEconomyExchangeByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    let exchangeObjNew = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_new_address = exchangeObjNew.address;

    await admin.upgradeEconomyExchangeByAdmins(exchange_new_address);   
  });
*/
   // Test Case: null address
   it('upgradeEconomyExchangeByAdmins-null-address', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

  //  await admin.upgradeEconomyExchangeByAdmins(null_address);   // error is expected
    await tryCatch(admin.upgradeEconomyExchangeByAdmins(null_address), errTypes.revert);
  });

   // Test Case: wasNotReplaced = false
/*   it('upgradeEconomyExchangeByAdmins-already-replaced', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    let new_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    await admin.replaceOneself(new_admin.address);

    let exchangeObjNew = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_new_address = exchangeObjNew.address;

  //  await admin.upgradeEconomyExchangeByAdmins(exchange_new_address);   // error is expected
    await tryCatch(admin.upgradeEconomyExchangeByAdmins(exchange_new_address), errTypes.revert);
  });
*/
   // Test Case: when admin not approve
   it('upgradeEconomyExchangeByAdmins-not-approved-by-admin', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    
    electorateAdmins_address = accounts[2];
    let not_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    let exchangeObjNew = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_new_address = exchangeObjNew.address;

   // await not_admin.upgradeEconomyExchangeByAdmins(exchange_new_address);   // error is expected
    await tryCatch(not_admin.upgradeEconomyExchangeByAdmins(exchange_new_address), errTypes.revert);
  });

  // Need DISCUSSION FOR NEXT TEST CASES -- PROBABLY NOT TO BE COVERED FOR THIS SMART CONTRACT

   // Test Case: when onlyAlive false
   // Test Case: when not owner but admin approve -- if this case exists -- should fail
   // Test Case: when owner but admin not approve -- should fail
   // Test Case: when owner and admin approve -- pass
   // Test Case: when not owner and not admin approved -- fail
   //===================================================================================================

/*  it('transferEtherByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    let address = accounts[1];
    let amount = new BigNumber(100000);

    await admin.transferEtherByAdmins(address, amount);
    
    assert.equal(true, false, "Address 0 =============> "+web3.eth.getBalance(accounts[0])+"Address 1 =============> "+web3.eth.getBalance(accounts[1]));
  });
*/  
   // Test Case: null address 
   it('transferEtherByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    // await admin.transferEtherByAdmins(null_address, 1000000);  // error expected
    await tryCatch(admin.transferEtherByAdmins(null_address, 1000000),errTypes.revert); // issue with the params
  });

  // Test Case: null value 
  it('transferEtherByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    let address1 = accounts[1];
    //await admin.transferEtherByAdmins(address1, 0);  // error expected
    await tryCatch(admin.transferEtherByAdmins(address1, 0),errTypes.revert); // params issue 
  });

  // Test Case: wasNotReplaced
  it('transferEtherByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    let new_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    //await admin.replaceOneself(new_admin.address);
    
    let address1 = accounts[1];
    
    //await admin.transferEtherByAdmins(address1, 10000);  // error expected
    //await tryCatch(admin.transferEtherByAdmins(address1, 1000000),errTypes.revert); // TODO: solve param issue
  });

   // Test Case: admin not approve
   it('transferEtherByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    electorateAdmins_address = accounts[2];
    let not_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    
    let address1 = accounts[1];
    
    //await not_admin.transferEtherByAdmins(address1, 10000);  // error expected
    //await tryCatch(not_admin.transferEtherByAdmins(address1, 1000000), errTypes.revert); // param issue
  });
   
   // ==================================================================================================

/*  it('payable-function', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;

    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    await admin.();
  });

  it('destroy-function', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;

    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    await admin.destroy();
  });
*/
});