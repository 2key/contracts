
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
    let acc2 = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b'; 

    let deployerAddress = accounts[0]; // '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
    const null_address = '0x0000000000000000000000000000000000000000';   

  
  /// getName method will work fine when address is known
  it('Case 1 getName Positive Test Case', async () => {

        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';
            
        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
        await adminContract.addNameToReg(name, address);

        let test_address = await regContract.getUserName2UserAddress(name);
        assert.equal(address, test_address, 'address stored for name not the same as address retrieved');

        let test_name = await regContract.getUserAddress2UserName(address);
        assert.equal(name, test_name, 'name stored for address is wrong');
  });

  /// getName method will not get the desired value if  name is fetched from random address
  it('Case 2 getName Negative Test Case', async () => {

        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);


        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';
        let random_address = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';
        
        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
        await adminContract.addNameToReg(name, address); 

        let test_name = await regContract.getUserAddress2UserName(random_address);

        assert.notEqual(name, test_name, 'name stored for address is wrong');
  });

  /// get address will work fine when name is know
  it('Case 3 getAddress Positive Test Case', async () => {
      
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';
        let random_name = 'new-name';

        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
        await adminContract.addNameToReg(name, address); 

        let test_address = await regContract.getUserName2UserAddress(name);
        assert.equal(address, test_address, 'address stored for name not the same as address retrieved');
  });

  /// get address will give undesired result when name is unknown
  it('Case 4 getAddress Negative Test Case', async () => {

        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';
        let random_name = 'new-name';

        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
        await adminContract.addNameToReg(name, address); 

        let test_address = await regContract.getUserName2UserAddress(random_name);
        assert.notEqual(address, test_address, 'address stored for name not the same as address retrieved');
  });
  
  /// New Name should be added to an Old Address
  it('Case 5 New Name should be added to an Old Address', async () => {
    
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);


        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

       await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
        await adminContract.addNameToReg(name, address);

        let new_name = 'new-account';

        await adminContract.addNameToReg(new_name, address);

        test_name = await regContract.getUserAddress2UserName(address);
        assert.equal(new_name, test_name, 'name stored for address is wrong'); 
  });

  /// New Name should be added to a New Address
  it('Case 6 New Name should be added to a New Address', async () => {
    
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
        await adminContract.addNameToReg(name, address);

        let new_name = 'new-account';
        let new_address = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';

        await adminContract.addNameToReg(new_name, new_address);

        test_address = await regContract.getUserName2UserAddress(new_name);
        assert.equal(new_address, test_address, 'address stored for name not the same as address retrieved');

        test_name = await regContract.getUserAddress2UserName(new_address);
        assert.equal(new_name, test_name, 'name stored for address is wrong'); 
  }); 

  /// Old Name should not be added to an Old Address
  it('Case 7 Old Name should not be added to an Old Address', async () => {
    
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
        await adminContract.addNameToReg(name, address);

        await tryCatch(adminContract.addNameToReg(name, address), errTypes.anyError);

        let test_address = await regContract.getUserName2UserAddress(name);
        assert.equal(address, test_address, 'address stored for name not the same as address retrieved'); 

        test_name = await regContract.getUserAddress2UserName(address);
        assert.equal(name, test_name, 'name stored for address is wrong'); 
  });

  /// Old Name should not be added to a New Address
  it('Case 8 Old Name should not be added to a New Address', async () => {
    
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);
        await adminContract.addNameToReg(name, address);

        let new_address = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';

        await tryCatch(adminContract.addNameToReg(name, new_address), errTypes.anyError);
      
        test_address = await regContract.getUserName2UserAddress(name);
        assert.equal(address, test_address, 'address stored for name not the same as address retrieved');
        
        test_name = await regContract.getUserAddress2UserName(address);
        assert.equal(name, test_name, 'name stored for address is wrong');
  });

  /// Non-Admin should not call methods which have onlyAdmin modifier
  it('Case 9 Non-Admin should not call methods which have onlyAdmin modifier', async () => {
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);

        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        let address = accounts[0];
        let name = 'account0-0';

        await tryCatch(regContract.addName(name, address), errTypes.anyError);
  });

  /// New entry will be added if no moderator set and is called by admin
  it('Case 10 : New entry will be added if not a moderator but admin', async () => {
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);

        let address = acc2;
        let name = 'account0-0';

        await adminContract.addNameToReg(name, address);
        let test_name = await regContract.getUserAddress2UserName(address);

        assert.equal(name, test_name, "Expected "+name+" but got "+test_name); 
  });

  /// New entery will be reverted if msg.sender is not moderator
  it('Case 11 : New entry will be reverted if msg.sender is neither moderator nor admin', async () => {
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);

        let address = acc2;
        let name = 'account0-0';

        let moderator = '0x3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9'; 
        await adminContract.addModeratorForReg(moderator);
        await tryCatch(regContract.addName(name, address), errTypes.anyError); /// msg.sender == deployerAddr so will throw error
  });

  /// New entry will be added if msg.sender is moderator
  it('Case 12 : New entry will be added if msg.sender is moderator', async () => {
        adminContract = await TwoKeyAdmin.new(deployerAddress); 
        economyContract = await TwoKeyEconomy.new(adminContract.address);
        eventSourceContract = await TwoKeyEventSource.new(adminContract.address);
        exchangeContarct = await TwoKeyExchange.new(1, deployerAddress, economyContract.address,adminContract.address);
        let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address);
        await adminContract.setSingletones(economyContract.address,exchangeContarct.address,regContract.address, eventSourceContract.address);

        let address = acc2;
        let name = 'account0-0';

        let moderator = '0x3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9'; 

        await adminContract.addModeratorForReg(moderator);
        await regContract.addName(name, address, {from: moderator});  
  });

  // it("Case 13 should add TwoKeyEventSource contract", async() => {
  //       let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address, {from: accounts[0]});
  //       await regContract.addTwoKeyEventSource(accounts[1], {from: accounts[0]});

  //       let eventSourceAddress = await regContract.getTwoKeyEventSourceAddress();

  //       assert.equal(eventSourceAddress, accounts[1], "wrong address");
  // });

  // it("Case 14 should fail if tried to call methods", async() => {
  //       let regContract = await TwoKeyReg.new(eventSourceContract.address, adminContract.address,{from: accounts[0]});

  //       //all 4 trnx should be reverted in order to pass the test
  //       await tryCatch(regContract.addWhereContractor(accounts[1],accounts[2]), 'revert');
  //       await tryCatch(regContract.addWhereModerator(accounts[1],accounts[2]), 'revert');
  //       await tryCatch(regContract.addWhereRefferer(accounts[1],accounts[2]), 'revert');
  //       await tryCatch(regContract.addWhereConverter(accounts[1],accounts[2]), 'revert');
  // });

});