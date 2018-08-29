const TwoKeyReg = artifacts.require("TwoKeyReg");

contract('TwoKeyReg', async (accounts) => {
  let tryCatch = require("./exceptions.js").tryCatch;
  let errTypes = require("./exceptions.js").errTypes;

  it('Case 1 getAddress_PositiveTestCase', async () => {
    let reg = await TwoKeyReg.new();
    let address = accounts[0];
    let name = 'account0-0';
    
    await reg.addName(name, address); // Updated second arg: '{from: address}' to 'address' to solve 'Error: Invalid number of arguments to Solidity function' while testing.

    let test_address = await reg.getName2Owner(name);
    assert.equal(address, test_address, 'address stored for name not the same as address retrieved');

    let test_name = await reg.getOwner2Name(address);
    assert.equal(name, test_name, 'name stored for address is wrong');
  });

  it('Case 2 getAddress_NegativeTestCase', async () => {
    let reg = await TwoKeyReg.new();
    let address = accounts[0];
    let name = 'account0-0';

    await reg.addName(name, address); 

    let random_address = accounts[1];
     //assert.(name, test_name, 'name stored for address is wrong');
    
    test_name = await reg.getOwner2Name(random_address);
    assert.notEqual(name, test_name, 'name stored for address is wrong');
  });

  it('getName_NegativeTestCase', async () => {
    let reg = await TwoKeyReg.new();
    let address = accounts[0];
    let name = 'account0-0';
    let random_name = 'new-name';

    await reg.addName(name, address); 

    let test_address = await reg.getName2Owner(random_name);
    assert.notEqual(address, test_address, 'address stored for name not the same as address retrieved');
  });
  

  it('getName_PositiveTestCase', async () => {
    let reg = await TwoKeyReg.new();
    let address = accounts[0];
    let name = 'account0-0';
    let random_name = 'new-name';

    await reg.addName(name, address); 

    let test_address = await reg.getName2Owner(name);
    assert.equal(address, test_address, 'address stored for name not the same as address retrieved');
  });
  

  it('add_New_Name_Old_Address_TestCase', async () => {
    let reg = await TwoKeyReg.new();
    let address = accounts[0];
    let name = 'account0-0';

    await reg.addName(name, address);

    let new_name = 'new-account';

    await reg.addName(new_name, address);

    test_name = await reg.getOwner2Name(address);
    assert.equal(new_name, test_name, 'name stored for address is wrong'); 
  });

  it('add_New_Name_New_Address_TestCase', async () => {
    let reg = await TwoKeyReg.new();
    let address = accounts[0];
    let name = 'account0-0';

    await reg.addName(name, address);

    new_name = 'new-account';
    let new_address = accounts[1];

    await reg.addName(new_name, new_address);

    test_address = await reg.getName2Owner(new_name);
    assert.equal(new_address, test_address, 'address stored for name not the same as address retrieved');

    test_name = await reg.getOwner2Name(new_address);
    assert.equal(new_name, test_name, 'name stored for address is wrong'); 
  }); 

  it('add_OLD_Name_Old_Addr_TestCase', async () => {
    let reg = await TwoKeyReg.new();
    let address = accounts[0];
    let name = 'account0-0';

    await reg.addName(name, address);

    await tryCatch(reg.addName(name, address), 'revert');

    let test_address = await reg.getName2Owner(name);
    assert.equal(address, test_address, 'address stored for name not the same as address retrieved'); 

    test_name = await reg.getOwner2Name(address);
    assert.equal(name, test_name, 'name stored for address is wrong'); 
  });

  it('add_Old_Name_New_Addr_TestCase', async () => {
    let reg = await TwoKeyReg.new();
    let address = accounts[0];
    let name = 'account0-0';

    await reg.addName(name, address);

    let new_address = accounts[1];

    await tryCatch(reg.addName(name, new_address), 'revert');
  
    test_address = await reg.getName2Owner(name);
    assert.equal(address, test_address, 'address stored for name not the same as address retrieved');
    
    test_name = await reg.getOwner2Name(address);
    assert.equal(name, test_name, 'name stored for address is wrong');
  });


  it("should add TwoKeyEventSource contract", async() => {
    let reg = await TwoKeyReg.new({from: accounts[0]});
    await reg.addTwoKeyEventSource(accounts[1], {from: accounts[0]});

    let eventSourceAddress = await reg.getTwoKeyEventSourceAddress();

    assert.equal(eventSourceAddress, accounts[1], "wrong address");
  });

  it("should fail if tried to call methods", async() => {
    let reg = await TwoKeyReg.new({from: accounts[0]});

    //all 4 trnx should be reverted in order to pass the test
    await tryCatch(reg.addWhereContractor(accounts[1],accounts[2]), 'revert');
    await tryCatch(reg.addWhereModerator(accounts[1],accounts[2]), 'revert');
    await tryCatch(reg.addWhereRefferer(accounts[1],accounts[2]), 'revert');
    await tryCatch(reg.addWhereConverter(accounts[1],accounts[2]), 'revert');

  });

});