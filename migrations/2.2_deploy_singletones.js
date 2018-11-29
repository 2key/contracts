const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegLogic = artifacts.require('TwoKeyRegLogic');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const Call = artifacts.require('Call');
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeContract = artifacts.require('TwoKeyExchangeContract');

var fs = require('fs');
/*
    TwoKeyCongress constructor need 2 addresses passed, the best'd be if we get that addresses static and always save the same ones
 */

module.exports = function deploy(deployer) {
  let proxyAddress;
  let adminInstance;
  let initialCongressMembers = [
    '0x4216909456e770FFC737d987c273a0B8cE19C13e', // Eitan
    '0x5e2B2b278445AaA649a6b734B0945Bd9177F4F03', // Kiki
  ];
  let maintainerAddress = (deployer.network.startsWith('rinkeby') || deployer.network.startsWith('public.')) ? '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f' : '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';
  let votingPowers = [1,1];
//0xb6736cdd635779a74a6bd359864cf2965a9d5113
  deployer.deploy(Call);
  if(deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('rinkeby') || deployer.network == 'ropsten') {
    deployer.deploy(TwoKeyCongress, 50, initialCongressMembers, votingPowers)
        .then(() => TwoKeyCongress.deployed())
        .then(() => deployer.deploy(TwoKeyAdmin,TwoKeyCongress.address))
        .then(() => TwoKeyAdmin.deployed())
        .then(async(instance) => {
            adminInstance = instance;
            console.log("ADMIN ADDRESS: " + TwoKeyAdmin.address);
        })
        .then(() => deployer.deploy(TwoKeyEconomy, TwoKeyAdmin.address))
        .then(() => deployer.deploy(TwoKeyUpgradableExchange, 95, TwoKeyAdmin.address, TwoKeyEconomy.address))
        .then(() => TwoKeyUpgradableExchange.deployed())
        .then(() => deployer.deploy(TwoKeyExchangeContract, [maintainerAddress], TwoKeyAdmin.address))
        .then(() => TwoKeyExchangeContract.deployed())
        .then(() => deployer.deploy(EventSource, TwoKeyAdmin.address))
        .then(() => deployer.deploy(TwoKeyRegLogic)
        .then(() => TwoKeyRegLogic.deployed())
        .then(() => deployer.deploy(TwoKeySingletonesRegistry))
        .then(() => TwoKeySingletonesRegistry.deployed().then(async(registry) => {
            console.log('... Adding TwoKeyRegLogic to Proxy registry as valid implementation');
            await new Promise(async(resolve,reject) => {
                try {
                    let txHash = await registry.addVersion("1.0",TwoKeyRegLogic.address);
                    const {logs} = await registry.createProxy("1.0");
                    const {proxy} = logs.find(l => l.event === 'ProxyCreated').args;
                    console.log('Proxy address: ' + proxy);
                    let obj = {};
                    obj['TwoKeyRegistryLogic'] = {
                        'address' : TwoKeyRegLogic.address,
                        'Proxy' : proxy,
                        'Version': "1.0"
                    };
                    await TwoKeyRegLogic.at(proxy).setInitialParams(EventSource.address, TwoKeyAdmin.address, (deployer.network.startsWith('rinkeby') || deployer.network.startsWith('public.')) ? '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f' : '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7');

                    fs.writeFile("./2key-protocol/src/proxyAddresses.json", JSON.stringify(obj,null,4), (err) => {
                        if (err) {
                            console.error(err);
                            return;
                        }
                        console.log("File has been created");
                    });
                    proxyAddress = proxy;
                    resolve(proxy);
                } catch (e) {
                    reject(e);
                }
            })
        }))
        .then(() => EventSource.deployed().then(async(eventSource) => {
            console.log("... Adding TwoKeyRegLogic to EventSource");
            await new Promise(async(resolve,reject) => {
                try {
                    let txHash = await eventSource.addTwoKeyReg(proxyAddress).then(() => true);
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });
            console.log("Added TwoKeyReg: " + proxyAddress + "  to EventSource : " + EventSource.address + "!")
        }))
        .then(async() => {
            await new Promise(async(resolve,reject) => {
                try {
                    let txHash = await adminInstance.setSingletones(TwoKeyEconomy.address, TwoKeyUpgradableExchange.address, proxyAddress, EventSource.address);
                    console.log('...Succesfully added singletones');
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });
        })
        .then(async() => {
            await new Promise(async(resolve,reject) => {
                try {
                    let txHash = await adminInstance.transfer2KeyTokens(TwoKeyUpgradableExchange.address, 10000000000000000000);
                    console.log('... Successfully transfered 2key tokens');
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            })
        })
        .then(() => true)
        .catch((err) => {
            console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
        }));
  } else if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
    deployer.link(Call,TwoKeyPlasmaEvents);
    deployer.deploy(TwoKeyPlasmaEvents);
  }
}
