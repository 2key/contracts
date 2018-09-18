
const TwoKeyAdmin = artifacts.require("TwoKeyAdmin");
const TwoKeyExchange = artifacts.require("TwoKeyUpgradableExchange");
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyEventSource = artifacts.require("TwoKeyEventSource");
const TwoKeyReg = artifacts.require("TwoKeyReg");

contract('TwoKeyReg', async (accounts) => {
    let tryCatch = require("./exceptions.js").tryCatch;
    let errTypes = require("./exceptions.js").errTypes;

    let adminContract;
    let exchangeContarct;
    let economyContract;
    let deployerAddress = '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
    const null_address = '0x0000000000000000000000000000000000000000';   
    const tokenName = 'TwoKeyEconomy';
    const symbol = '2Key';
    const decimals = 18;
    const totalSupply = 1000000000000000000000000000;  

    before(async() => {
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
    });

  /// getName method will work fine when address is known
  it('Case 1 getName Positive Test Case', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';
        
        await adminContract.addNameToReg(name, address);

        let test_address = await regContract.getName2Owner(name);
        assert.equal(address, test_address, 'address stored for name not the same as address retrieved');

        let test_name = await regContract.getOwner2Name(address);
        assert.equal(name, test_name, 'name stored for address is wrong');
  });

  /// getName method will not get the desired value if  name is fetched from random address
  it('Case 2 getName Negative Test Case', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';
        let random_address = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';
        
        await adminContract.addNameToReg(name, address); 

        let test_name = await regContract.getOwner2Name(random_address);

        assert.notEqual(name, test_name, 'name stored for address is wrong');
  });

  /// get address will work fine when name is know
  it('Case 3 getAddress Positive Test Case', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';
        let random_name = 'new-name';

        await adminContract.addNameToReg(name, address); 

        let test_address = await regContract.getName2Owner(name);
        assert.equal(address, test_address, 'address stored for name not the same as address retrieved');
  });

  /// get address will give undesired result when name is unknown
  it('Case 4 getAddress Negative Test Case', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';
        let random_name = 'new-name';

        await adminContract.addNameToReg(name, address); 

        let test_address = await regContract.getName2Owner(random_name);
        assert.notEqual(address, test_address, 'address stored for name not the same as address retrieved');
  });
  
  /// New Name should be added to an Old Address
  it('Case 5 New Name should be added to an Old Address', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await adminContract.addNameToReg(name, address);

        let new_name = 'new-account';

        await adminContract.addNameToReg(new_name, address);

        test_name = await regContract.getOwner2Name(address);
        assert.equal(new_name, test_name, 'name stored for address is wrong'); 
  });

  /// New Name should be added to a New Address
  it('Case 6 New Name should be added to a New Address', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await adminContract.addNameToReg(name, address);

        let new_name = 'new-account';
        let new_address = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';

        await adminContract.addNameToReg(new_name, new_address);

        test_address = await regContract.getName2Owner(new_name);
        assert.equal(new_address, test_address, 'address stored for name not the same as address retrieved');

        test_name = await regContract.getOwner2Name(new_address);
        assert.equal(new_name, test_name, 'name stored for address is wrong'); 
  }); 

  /// Old Name should not be added to an Old Address
  it('Case 7 Old Name should not be added to an Old Address', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await adminContract.addNameToReg(name, address);

        await tryCatch(adminContract.addNameToReg(name, address), errTypes.anyError);

        let test_address = await regContract.getName2Owner(name);
        assert.equal(address, test_address, 'address stored for name not the same as address retrieved'); 

        test_name = await regContract.getOwner2Name(address);
        assert.equal(name, test_name, 'name stored for address is wrong'); 
  });

  /// Old Name should not be added to a New Address
  it('Case 8 Old Name should not be added to a New Address', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await adminContract.addNameToReg(name, address);

        let new_address = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';

        await tryCatch(adminContract.addNameToReg(name, new_address), errTypes.anyError);
      
        test_address = await regContract.getName2Owner(name);
        assert.equal(address, test_address, 'address stored for name not the same as address retrieved');
        
        test_name = await regContract.getOwner2Name(address);
        assert.equal(name, test_name, 'name stored for address is wrong');
  });

  /// Non-Admin should not call methods which have onlyAdmin modifier
  it('Case 9 Non-Admin should not call methods which have onlyAdmin modifier', async () => {
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await tryCatch(regContract.addName(name, address), errTypes.anyError);
  });

  // it("Case 10 should add TwoKeyEventSource contract", async() => {
  //       let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address, {from: accounts[0]});
  //       await regContract.addTwoKeyEventSource(accounts[1], {from: accounts[0]});

  //       let eventSourceAddress = await regContract.getTwoKeyEventSourceAddress();

  //       assert.equal(eventSourceAddress, accounts[1], "wrong address");
  // });

  // it("Case 11 should fail if tried to call methods", async() => {
  //       let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address,{from: accounts[0]});

  //       //all 4 trnx should be reverted in order to pass the test
  //       await tryCatch(regContract.addWhereContractor(accounts[1],accounts[2]), 'revert');
  //       await tryCatch(regContract.addWhereModerator(accounts[1],accounts[2]), 'revert');
  //       await tryCatch(regContract.addWhereRefferer(accounts[1],accounts[2]), 'revert');
  //       await tryCatch(regContract.addWhereConverter(accounts[1],accounts[2]), 'revert');
  // });

});