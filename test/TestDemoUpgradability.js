const LogicOne = artifacts.require("LogicOne");
const LogicTwo = artifacts.require("LogicTwo");
const Registry = artifacts.require("Registry");


contract('Registry', async() => {
    let logOne,logTwo,registry;

    it('should deploy registry and logic one and logic two',async() => {
        registry = await Registry.new();

        logOne = await LogicOne.new();
        logTwo = await LogicTwo.new();

        await registry.setLogicContract(logOne.address);

        let add = await registry.logic_contract();

        assert.equal(add, logOne.address);
    });

    it('should set value there', async() => {
        await LogicOne.at(registry.address).setVal(3);

        let value = await LogicOne.at(registry.address).val();
        console.log('Value is: ' + value);
    });


    it('should get value from new contract', async() => {
        await registry.setLogicContract(logTwo.address);

        let value = await LogicTwo.at(registry.address).val();
        console.log('Value is: ' + value);
    })
})