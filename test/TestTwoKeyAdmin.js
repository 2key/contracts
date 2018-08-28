const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyEconomy = artifacts.require("TwoKeyEconomy");
const TwoKeyExchange = artifacts.require("TwoKeyUpgradableExchange");
const ethers = require("./utils");

contract('TwoKeyAdmin', async (accounts) => {
  let tryCatch = require("./exceptions.js").tryCatch;
  let errTypes = require("./exceptions.js").errTypes;
  
  let electorateAdmins_address = accounts[0];
  let coinbase = accounts[0];
  let rate = 1;

  //const BigNumber = web3.BigNumber;
 // const tokens = new BigNumber(100);

  const null_address = '0x0000000000000000000000000000000000000000';

  //============================================================================================================
  // TEST CASES FOR INITIAL

  // Test Case: Passing null_address as Economy Address should revert
 it('Initial :: Null-Economy-Address-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
    let exchange_address = exchangeObj.address;
    
    //await TwoKeyAdmin.new(null_address, electorateAdmins_address, exchange_address, {from: coinbase});
    await tryCatch(TwoKeyAdmin.new(null_address, electorateAdmins_address, exchange_address), errTypes.anyError);
  });

 //  // Test Case: Passing null_address as ElectorateAdmins Address should revert  
  it('Initial :: Null-ElectorateAdmins-Address-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
    let exchange_address = exchangeObj.address;

    await tryCatch(TwoKeyAdmin.new(economy_address, null_address, exchange_address), errTypes.anyError);  
  });

 //  // Test Case: Passing null_address as Exchange Address should revert  
  it('Initial :: Null-Exchange-Address-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
    await tryCatch(TwoKeyAdmin.new(economy_address, electorateAdmins_address, null), errTypes.anyError)
   // await tryCatch(TwoKeyAdmin.new(economy_address, electorateAdmins_address, null_address), errTypes.anyError);
  });

  // Test Case: Passing non null addresses in all three should not revert
  it('Initial :: Non-Null-Parameters-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
    let exchange_address = exchangeObj.address;

    await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from: coinbase});
  });
  //============================================================================================================
  // TEST CASES FOR REPLACE

  // Test Case: Passing null address as admincontract address should revert
  it('Replace :: Passing-Null-Address-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    
    await tryCatch(admin.replaceOneself(null_address), errTypes.anyError); // null address check is required in sol ! (here error is catched due to revert thrown by transfer)
  });

  // Test Case: Passing admincontract address which is already replaced once should revert
  //Need to work on it after re code of Admin
    it('Replace :: Already-Replaced-AdminContract-TestCase', async () => {
      let economyObj = await TwoKeyEconomy.new({from: coinbase});
      let economy_address = economyObj.address;
      let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
      let exchange_address = exchangeObj.address;

      let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from: coinbase});

      let new_economyObj = await TwoKeyEconomy.new({from: coinbase});
      let new_economy_address = new_economyObj.address;
      let new_exchangeObj = await TwoKeyExchange.new(rate, coinbase, new_economy_address, {from: coinbase});
      let new_exchange_address = new_exchangeObj.address;

      let new_admin = await TwoKeyAdmin.new(new_economy_address, electorateAdmins_address, new_exchange_address, {from: coinbase});
      
      await admin.replaceOneself(new_admin.address, {from: coinbase});  

      await tryCatch(admin.replaceOneself(admin.address), errTypes.revert); 
    });

  // Test Case: Passing admincontract address which is not admin Voting Approved should revert
  // create new accounts to test this case
  it('Replace :: Address-Not-Approved-By-Admin-TestCase', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    electorateAdmins_address = accounts[2];
    let not_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    await tryCatch(not_admin.replaceOneself(admin.address), errTypes.anyError);  
  });


  // Test Case: Positive scenarios where Replace should work
  // Need to be taken care after re writing the admin contract
  it('Replace', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    let new_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

    const adminContract_balance = web3.eth.getBalance(admin.address);

     await admin.replaceOneself(new_admin.address);
   
    let adminContract_new_balance = await web3.eth.getBalance(admin.address);
    //assert.equal(true,false, 'admin address = '+ adminContract_balance+ ' ===========> '+ adminContract_new_balance); 
    assert.equal(adminContract_balance, adminContract_new_balance, ' Message');     // balances are 0 still assertion fails    
  });

  //===================================================================================
  // TEST CASES FOR transferByAdmin


  // Need to be taken care of after modifying admin contract (required Statement missing)
  it('transferByAdmins-null-address', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from: coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    
    tokens = new web3.BigNumber(0);
    //const balanceValue = await web3.eth.getBalance(coinbase);

    //assert.equal(true, false, "==========> "+ balanceValue)

   //await admin.transferByAdmins(coinbase, tokens);   // null address check is reuired in sol !
   await tryCatch(admin.transferByAdmins(null_address, tokens), errTypes.anyError); // error is catched due to transfer or parameters are not passed correctly
  });


  // need to add require statement in sol
  it('transferByAdmins-null-value', async () => {
    let economyObj = await TwoKeyEconomy.new({from: coinbase});
    let economy_address = economyObj.address;

    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});
  
//    await admin.transferByAdmins(wallet, 10);   // null value check is reuired in sol !
    await tryCatch(admin.transferByAdmins(coinbase, 0), errTypes.anyError);   // error is catched due to transfer or parameters are not passed correctly
  });
  
  // Test Case: When adminContract already replaced
  // need to work on it after modifying admin contract
  it('transferByAdmins-adminContract-already-replaced', async () => {
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
    
  // Test Case: When calling address not approved by admin
  it('transferByAdmins-adminContract-not-approved-by-admin', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});
    electorateAdmins_address = accounts[2];
    let not_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});

    const tokens = new web3.BigNumber(1000);
  //  await not_admin.transferByAdmins(wallet, 1000000 );   // expected error -- add tryCatch
    await tryCatch(not_admin.transferByAdmins(coinbase, tokens ), errTypes.anyError); // revert is due to incorrect params
  });

// need to re work after admin modifications
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
  // TEST CASES for Upgradable Exchange Method 

  it('upgradeEconomyExchangeByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});

    let exchangeObjNew = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_new_address = exchangeObjNew.address;

    await admin.upgradeEconomyExchangeByAdmins(exchange_new_address);   
  });

   // Test Case: null address
   // require statement missing
   it('upgradeEconomyExchangeByAdmins-null-address', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});

  //  await admin.upgradeEconomyExchangeByAdmins(null_address);   // error is expected
    await tryCatch(admin.upgradeEconomyExchangeByAdmins(null_address), errTypes.revert);
  });

   // Test Case: wasNotReplaced = false
   // Need to redo after admin contract modification
   it('upgradeEconomyExchangeByAdmins-already-replaced', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});
    let new_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});

    await admin.replaceOneself(new_admin.address);

    let exchangeObjNew = await TwoKeyExchange.new(rate, coinbase, economy_address);
    let exchange_new_address = exchangeObjNew.address;

  //  await admin.upgradeEconomyExchangeByAdmins(exchange_new_address);   // error is expected
    await tryCatch(admin.upgradeEconomyExchangeByAdmins(exchange_new_address), errTypes.revert);
  });

   // Test Case: when admin not approve
   it('upgradeEconomyExchangeByAdmins-not-approved-by-admin', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});
    
    electorateAdmins_address = accounts[2];
    let not_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});

    let exchangeObjNew = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_new_address = exchangeObjNew.address;

   // await not_admin.upgradeEconomyExchangeByAdmins(exchange_new_address);   // error is expected
    await tryCatch(not_admin.upgradeEconomyExchangeByAdmins(exchange_new_address), errTypes.revert);
  });

   //===================================================================================================
  // TEST CASES for Transfer Ethers By Admin Method

  // Re work required
  it('transferEtherByAdmins', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address,{from:coinbase});

    let address = accounts[1];
    let amount = new BigNumber(100);

    await admin.transferEtherByAdmins(address, amount);
    
    //assert.equal(true, false, "Address 0 =============> "+web3.eth.getBalance(accounts[0])+"Address 1 =============> "+web3.eth.getBalance(accounts[1]));
  });
  
   // Test Case: null address 
   it('transferEtherByAdmins - null address', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});

    const ethers = new web3.BigNumber(10);
    // await admin.transferEtherByAdmins(null_address, 1000000);  // error expected
    await tryCatch(admin.transferEtherByAdmins(null_address, ethers),errTypes.anyError); // issue with the params
  });

  // Test Case: null value
  it('transferEtherByAdmins - null value', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});
    let address1 = accounts[1];

    const ethers = new web3.BigNumber(0);
    //await admin.transferEtherByAdmins(address1, 0);  // error expected
    await tryCatch(admin.transferEtherByAdmins(coinbase, ethers),errTypes.anyError); // params issue 
  });

  // Test Case: wasNotReplaced
  // need to redo after admin contract modifications
  it('transferEtherByAdmins - already - replaced', async () => {
    let economyObj = await TwoKeyEconomy.new();
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    let new_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);
    //await admin.replaceOneself(new_admin.address);
    
    let address1 = accounts[1];
    const ethers = new web3.BigNumber(1000); 

    //await admin.transferEtherByAdmins(address1, 10000);  // error expected
    await tryCatch(admin.transferEtherByAdmins(address1, ethers),errTypes.revert); // TODO: solve param issue
  });

   // Test Case: admin not approve
   it('transferEtherByAdmins -not-approved-by-admin', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});
    electorateAdmins_address = accounts[2];
    let not_admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});
    
    let address1 = accounts[1];
    const ethers = new web3.BigNumber(1000); 
    
    //await not_admin.transferEtherByAdmins(address1, 10000);  // error expected
    await tryCatch(not_admin.transferEtherByAdmins(address1, ethers), errTypes.anyError); // param issue
  });
   
   // ==================================================================================================

  // need to redo after admin contract
  // it('payable-function', async () => {
  //   let economyObj = await TwoKeyEconomy.new();
  //   let economy_address = economyObj.address;

  //   let exchangeObj = await TwoKeyExchange.new(rate, wallet, economy_address);
  //   let exchange_address = exchangeObj.address;

  //   let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address);

  //   await admin.();
  // });

  it('destroy-function', async () => {
    let economyObj = await TwoKeyEconomy.new({from:coinbase});
    let economy_address = economyObj.address;
    let exchangeObj = await TwoKeyExchange.new(rate, coinbase, economy_address, {from:coinbase});
    let exchange_address = exchangeObj.address;

    let admin = await TwoKeyAdmin.new(economy_address, electorateAdmins_address, exchange_address, {from:coinbase});

    await admin.destroy();

    assert.equal(null_address, admin.address, "admin address should be undefined");
  });

});