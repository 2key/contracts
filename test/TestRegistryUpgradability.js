const TwoKeyReg = artifacts.require("TwoKeyReg");
const TwoKeyRegistryProxy = artifacts.require("TwoKeyRegistryProxy");
const TwoKeyRegistryStorage = artifacts.require("TwoKeyRegistryStorage");



contract('TwoKeyReg', async(accounts) => {
    let registryInstance;
    let proxyInstance;

    /*
            TwoKeyRegistryStorage
                   /      \
                  /        \
                 /          \
                /            \
    TwoKeyRegistryProxy    TwoKeyReg

     */

    before(async() => {
        registryInstance = await TwoKeyReg.new(accounts[0],accounts[0],accounts[0],{from: accounts[0]});
        proxyInstance = await TwoKeyRegistryProxy.new({from: accounts[0]});
        await proxyInstance.setLogicContract(registryInstance.address);
        console.log('Successfully added registry to proxy');
        let add = await proxyInstance.logic_contract();
        assert.equal(add, registryInstance.address, 'should be the same');
    });


    it('should set value there', async() => {
        await TwoKeyReg.at(proxyInstance.address).setValue(55);
        console.log('Done');

        let val = await TwoKeyReg.at(proxyInstance.address).getValue();
        console.log('Value is: ' + val);
    });




});