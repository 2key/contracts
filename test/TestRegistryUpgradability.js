const TwoKeyRegLogic = artifacts.require('TwoKeyRegLogic');
const TwoKeyRegLogicV1 = artifacts.require('TwoKeyRegLogicV1');
const Registry = artifacts.require('Registry');
const Proxy = artifacts.require('UpgradeabilityProxy');


contract('Upgradeable', async(accounts) => {

    it('should work', async() =>  {
        const impl_v1_0 = await TwoKeyRegLogic.new(accounts[0],accounts[0],accounts[0]);
        const impl_v1_1 = await TwoKeyRegLogicV1.new(accounts[0],accounts[0],accounts[0]);

        const registry = await Registry.new();
        await registry.addVersion("1.0", impl_v1_0.address);
        await registry.addVersion("1.1", impl_v1_1.address);

        const {logs} = await registry.createProxy("1.0");

        const {proxy} = logs.find(l => l.event === 'ProxyCreated').args;

        await TwoKeyRegLogic.at(proxy).setValue(5);
        let value = await TwoKeyRegLogic.at(proxy).getValue();
        console.log(value);

        await Proxy.at(proxy).upgradeTo("1.1");

        let value1 = await TwoKeyRegLogicV1.at(proxy).getValue();
        console.log(value1);
        await TwoKeyRegLogicV1.at(proxy).setValue(9);
        value1 = await TwoKeyRegLogicV1.at(proxy).getValue();
        console.log(value1);
    })

})