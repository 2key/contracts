const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');

contract("TwoKeyEconomy", async (accounts) => {


    let randomActorAddress1 = '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';
    let randomActorAddress2 = '0xbEde520368f2Df7BED4dF5185101f303f6c7d4cc';

    let deployerAdrress = '0xb3FA520368f2Df7BED4dF5185101f303f6c7decc';

    let economyContract;
    const tokenName = 'TwoKeyEconomy';
    const symbol = '2KEY';
    const decimals = 18;
    const totalSupply = 1000000000000000000000000000;

    cosole.log('Testing');

    it("Test: Admin and SingletonRegistry contract addresses should be properly set", async () => {
        console.log('CAO');

        economyContract = await TwoKeyEconomy.new(randomActorAddress1, randomActorAddress2);
        //Validate admin address
        let admin = await economyContract.twoKeyAdmin();
        assert.equal(randomActorAddress1, admin, 'admin address is not properly set');

        //Validate singleton registry address
        let singletonReg = await economyContract.twoKeySingletonRegistry();
        assert.equal(randomActorAddress2, singletonReg, 'singleton registry address is not properly set');
    });

    it('Test: Token name and token symbol should be properly set', async () => {
        let name = await TwoKeyEconomy.name();
        assert.equal(name, tokenName, 'token name is not properly assigned');

        let sym = await TwoKeyEconomy.symbol();
        assert.equal(sym, symbol, 'token symbol is not properly set');
    });

    it('Test: Token decimals should be properly set', async () => {
        let dec = await TwoKeyEconomy.decimals();
        assert.equal(dec, decimals, 'token decimals should be properly set');
    });


});

