const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyRegistryV1 = artifacts.require('TwoKeyRegistryV1');
const Registry = artifacts.require('Registry');
const Proxy = artifacts.require('UpgradeabilityProxy');

contract('Upgradeable', async(accounts) => {

    it('should work', async() =>  {
        const impl_v1_0 = await TwoKeyRegistry.new();
        const impl_v1_1 = await TwoKeyRegistryV1.new();


        const registry = await Registry.new();

        await registry.addVersion("1.0", impl_v1_0.address);

        const {logs} = await registry.createProxy("1.0");

        const {proxy} = logs.find(l => l.event === 'ProxyCreated').args;

        // proxy is the main address for everything

        TwoKeyRegLogic.at(proxy).setInitialParams(accounts[0],accounts[0],accounts[0]);

        await TwoKeyRegistry.at(proxy).setValue(5);
        let value = await TwoKeyRegistry.at(proxy).getValue();
        console.log('First value is: ' + value);
        assert.equal(value,5,'values are not same 1');


        let maint = await TwoKeyRegistry.at(proxy).getMaintainers();
        console.log(maint);

        await registry.addVersion("1.1", impl_v1_1.address);
        await Proxy.at(proxy).upgradeTo("1.1");


        let value1 = await TwoKeyRegistryV1.at(proxy).getValue();
        console.log(value1);

        await TwoKeyRegistryV1.at(proxy).setValue(9);
        let value2 = await TwoKeyRegistryV1.at(proxy).getValue();
        console.log(value2);

        maint = await TwoKeyRegistryV1.at(proxy).getMaintainers();
        console.log(maint);
        // assert.equal(value2,14,'values are not same 3');

        // assert.equal(value22, 25,'values are not same 4');
    })

});