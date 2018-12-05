const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const Call = artifacts.require('Call');
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeContract = artifacts.require('TwoKeyExchangeContract');
const file = require('../2key-protocol/src/proxyAddresses.json');
var fs = require('fs');
/*
    TwoKeyCongress constructor need 2 addresses passed, the best'd be if we get that addresses static and always save the same ones
 */

module.exports = function deploy(deployer) {
    /**
     * Read the file firts
     */
let networkId;
    if(deployer.network.startsWith('ropsten')) {
        networkId = 3;
    } else if(deployer.network.startsWith('rinkeby')) {
        networkId = 4;
    } else if (deployer.network.startsWith('public')) {
        networkId = 3;
    } else if(deployer.network.startsWith('dev')) {
        networkId = 8086;
    }
  let fileObject = {};
  if(fs.existsSync(file)) {
        fileObject = JSON.parse(fs.readFileSync(file,{encoding: 'utf8'}));
  }
  let proxyAddressTwoKeyRegistry;
  let proxyAddressTwoKeyEventSource;
  let adminInstance;
  let initialCongressMembers = [
    '0x4216909456e770FFC737d987c273a0B8cE19C13e', // Eitan
    '0x5e2B2b278445AaA649a6b734B0945Bd9177F4F03', // Kiki
  ];
  let maintainerAddress = (deployer.network.startsWith('ropsten') || deployer.network.startsWith('rinkeby') || deployer.network.startsWith('public.')) ? '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f' : '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';
  let votingPowers = [1,1];
//0xb6736cdd635779a74a6bd359864cf2965a9d5113
  deployer.deploy(Call);
  if(deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('rinkeby') || deployer.network.startsWith('ropsten')) {
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
        .then(() => deployer.deploy(EventSource))
        .then(() => deployer.deploy(TwoKeyRegistry)
        .then(() => TwoKeyRegistry.deployed())
        .then(() => deployer.deploy(TwoKeySingletonesRegistry, [maintainerAddress], TwoKeyAdmin.address))
        .then(() => TwoKeySingletonesRegistry.deployed().then(async(registry) => {
            console.log('... Adding TwoKeyRegistry to Proxy registry as valid implementation');
            await new Promise(async(resolve,reject) => {
                try {
                    /**
                     * Adding TwoKeyRegistry to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                     */

                    let txHash = await registry.addVersion("TwoKeyRegistry", "1.0",TwoKeyRegistry.address);
                    let {logs} = await registry.createProxy("TwoKeyRegistry", "1.0");
                    let {proxy} = logs.find(l => l.event === 'ProxyCreated').args;
                    console.log('Proxy address for the TwoKeyRegistry is : ' + proxy);
                    const twoKeyReg = fileObject.TwoKeyRegistry || {};

                    twoKeyReg[networkId] =  {
                        'address': TwoKeyRegistry.address,
                        'Proxy': proxy,
                        'Version': "1.0"
                    };


                    fileObject['TwoKeyRegistry'] = twoKeyReg;
                    proxyAddressTwoKeyRegistry = proxy;
                    resolve(proxy);
                } catch (e) {
                    reject(e);
                }
            });

            console.log('... Adding EventSource to Proxy registry as valid implementation');
            await new Promise(async(resolve,reject) => {
                try {
                    /**
                     * Adding EventSource to the registry, deploying 1st proxy for that 1.0 version of EventSource and setting initial params there
                     */
                    let txHash = await registry.addVersion("TwoKeyEventSource", "1.0", EventSource.address);
                    let {logs} = await registry.createProxy("TwoKeyEventSource", "1.0");
                    let {proxy} = logs.find(l => l.event === 'ProxyCreated').args;
                    console.log('Proxy address for the EventSource is : ' + proxy);

                    const twoKeyEventS = fileObject.TwoKeyEventSource || {};

                    twoKeyEventS[networkId] =  {
                        'address': EventSource.address,
                        'Proxy': proxy,
                        'Version': "1.0"
                    };
                    fileObject['TwoKeyEventSource'] = twoKeyEventS;
                    proxyAddressTwoKeyEventSource = proxy;

                    /**
                     * Writing object with all informations to json file
                     */

                    fs.writeFile("./2key-protocol/src/proxyAddresses.json", JSON.stringify(fileObject,null,4), (err) => {
                        if (err) {
                            console.error(err);
                            return;
                        }
                        console.log("File has been created");
                    });
                    resolve(proxy);
                } catch (e) {
                    reject(e);
                }
            })
            console.log('... Setting Initial params in both contracts');
            await new Promise(async(resolve,reject) => {
                try {
                    /**
                     * Setting initial parameters in event source and twoKeyRegistry contract
                     */
                    await EventSource.at(proxyAddressTwoKeyEventSource).setInitialParams(TwoKeyAdmin.address);
                    let txHash = await TwoKeyRegistry.at(proxyAddressTwoKeyRegistry).setInitialParams(proxyAddressTwoKeyEventSource, TwoKeyAdmin.address, (deployer.network.startsWith('rinkeby') || deployer.network.startsWith('public.')) ? '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f' : '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7');
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            })
        }))
        .then(() => EventSource.deployed().then(async() => {
            console.log("... Adding TwoKeyRegistry to EventSource");
            await new Promise(async(resolve,reject) => {
                try {
                    let txHash = await EventSource.at(proxyAddressTwoKeyEventSource).addTwoKeyReg(proxyAddressTwoKeyRegistry).then(() => true);
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });
            console.log("Added TwoKeyReg: " + proxyAddressTwoKeyRegistry + "  to EventSource : " + proxyAddressTwoKeyEventSource + "!")
        }))
        .then(async() => {
            await new Promise(async(resolve,reject) => {
                try {
                    let txHash = await adminInstance.setSingletones(TwoKeyEconomy.address, TwoKeyUpgradableExchange.address, proxyAddressTwoKeyRegistry, proxyAddressTwoKeyEventSource);
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
