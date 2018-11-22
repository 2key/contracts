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

        console.log('Registry address: ' + registryInstance);
        console.log('Proxy address: '+  proxyInstance);
    });

    it('should set registry to proxy', async() => {
        await proxyInstance.setLogicContract(registryInstance.address);
        console.log('Successfully added registry to proxy');

        let add = await proxyInstance.logic_contract();
        assert.equal(add, registryInstance.address, 'should be the same');
    });

    it('should load registry from proxy address', async() => {
        await TwoKeyReg.at(proxyInstance.address).setValue(55);
        console.log('Done');
        let val =await registryInstance.getValue();
        console.log('Value is: ' + val);
    });




});