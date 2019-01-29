const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const Call = artifacts.require('Call');
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');

module.exports = function deploy(deployer) {
    /**
     * Determine network id first
     */
    let networkId;
    if (deployer.network.startsWith('ropsten')) {
        networkId = 3;
    } else if (deployer.network.startsWith('rinkeby')) {
        networkId = 4;
    } else if (deployer.network.startsWith('public')) {
        networkId = 3;
    } else if (deployer.network.startsWith('dev-local')) {
        networkId = 8086;
    } else if (deployer.network.startsWith('development')) {
        networkId = 'ganache';
    } else if (deployer.network.startsWith('private')) {
        networkId = 98052;
    }

    /**
     * Read the proxy file into fileObject
     * @type {{}}
     */
    let fileObject = {};
    if (fs.existsSync(proxyFile)) {
        fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
    }

    /**
     * Define proxyAddress variables for the contracts
     */
    let proxyAddressTwoKeyRegistry;
    let proxyAddressTwoKeyEventSource;
    let proxyAddressTwoKeyExchange;
    let proxyAddressTwoKeyAdmin;
    let proxyAddressTwoKeyUpgradableExchange;

    /**
     * Define proxy address for plasma network
     */
    let proxyAddressTwoKeyPlasmaEvents;


    /**
     * Initial variables we need for contracts initial state
     */
    let initialCongressMembers = [
        '0x4216909456e770FFC737d987c273a0B8cE19C13e', // Eitan
        '0x5e2B2b278445AaA649a6b734B0945Bd9177F4F03', // Kiki

    ];
    let deployerAddress = '0x18e1d5ca01141E3a0834101574E5A1e94F0F8F6a';
    let maintainerAddresses = [];

    if(deployer.network.startsWith('public.test')) {
        maintainerAddresses = [
            '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f',
            '0x098a12404fd3f5a06cfb016eb7669b1c41419705' ,
            '0x1d55762a320e6826cf00c4f2121b7e53d23f6822'
        ]
    } else {
        maintainerAddresses = [
            '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7'
        ]
    }
    let votingPowers = [1, 1];

    /**
     * Deployment process
     */
    deployer.deploy(Call);
    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('rinkeby') || deployer.network.startsWith('ropsten')) {
        deployer.deploy(TwoKeyCongress, 50, initialCongressMembers, votingPowers)
            .then(() => TwoKeyCongress.deployed())
            .then(() => deployer.deploy(TwoKeyAdmin))
            .then(() => TwoKeyAdmin.deployed())
            .then(() => deployer.deploy(TwoKeyExchangeRateContract))
            .then(() => TwoKeyExchangeRateContract.deployed())
            .then(() => deployer.deploy(EventSource))
            .then(() => deployer.link(Call, TwoKeyRegistry))
            .then(() => deployer.deploy(TwoKeyRegistry)
            .then(() => TwoKeyRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyUpgradableExchange))
            .then(() => TwoKeyUpgradableExchange.deployed())
            .then(() => deployer.deploy(TwoKeySingletonesRegistry, [], '0x0')) //adding empty admin address
            .then(() => TwoKeySingletonesRegistry.deployed().then(async (registry) => {
                /**
                 * Here we will be adding all contracts to the Registry and create a Proxies for them
                 */
                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyRegistry to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyRegistry to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyRegistry", "1.0", TwoKeyRegistry.address);
                        let { logs } = await registry.createProxy("TwoKeyRegistry", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the TwoKeyRegistry is : ' + proxy);
                        const twoKeyReg = fileObject.TwoKeyRegistry || {};
                        console.log(maintainerAddresses);
                        twoKeyReg[networkId] = {
                            'address': TwoKeyRegistry.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: maintainerAddresses,
                        };


                        fileObject['TwoKeyRegistry'] = twoKeyReg;
                        proxyAddressTwoKeyRegistry = proxy;
                        resolve(proxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding EventSource to Proxy registry as valid implementation');
                        /**
                         * Adding EventSource to the registry, deploying 1st proxy for that 1.0 version of EventSource and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyEventSource", "1.0", EventSource.address);
                        let { logs } = await registry.createProxy("TwoKeyEventSource", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the EventSource is : ' + proxy);

                        const twoKeyEventS = fileObject.TwoKeyEventSource || {};

                        twoKeyEventS[networkId] = {
                            'address': EventSource.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: deployerAddress,
                        };
                        fileObject['TwoKeyEventSource'] = twoKeyEventS;
                        proxyAddressTwoKeyEventSource = proxy;
                        resolve(proxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyExchangeRateContract to Proxy registry as valid implementation');
                        /**
                         * Adding EventSource to the registry, deploying 1st proxy for that 1.0 version of EventSource
                         */
                        let txHash = await registry.addVersion("TwoKeyExchangeRateContract", "1.0", TwoKeyExchangeRateContract.address);
                        let { logs } = await registry.createProxy("TwoKeyExchangeRateContract", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the TwoKeyExchangeRateContract is : ' + proxy);

                        const twoKeyExchangeRate = fileObject.TwoKeyExchange || {};

                        twoKeyExchangeRate[networkId] = {
                            'address': TwoKeyExchangeRateContract.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: maintainerAddresses,
                        };
                        fileObject['TwoKeyExchangeRateContract'] = twoKeyExchangeRate;
                        proxyAddressTwoKeyExchange = proxy;

                        resolve(proxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyAdmin contract to proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyAdmin to the registry, deploying 1st proxy for that 1.0 version of TwoKeyAdmin
                         */
                        let txHash = await registry.addVersion("TwoKeyAdmin", "1.0", TwoKeyAdmin.address);
                        let { logs } = await registry.createProxy("TwoKeyAdmin", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the TwoKeyAdmin contract is : ' + proxy);


                        // txHash = await TwoKeyAdmin.at(proxy).transfer2KeyTokens(proxyAddressTwoKeyRegistry, 1000000000000000);
                        const twoKeyAdmin = fileObject.TwoKeyAdmin || {};
                        twoKeyAdmin[networkId] = {
                            'address': TwoKeyAdmin.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: deployerAddress
                        };

                        fileObject['TwoKeyAdmin'] = twoKeyAdmin;
                        proxyAddressTwoKeyAdmin = proxy;

                        resolve(proxy);

                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyUpgradableExchange contract to proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyUpgradableExchange to the registry, deploying 1st proxy for that 1.0 version of TwoKeyUpgradableExchange
                         */
                        let txHash = await registry.addVersion("TwoKeyUpgradableExchange", "1.0", TwoKeyUpgradableExchange.address);
                        let { logs } = await registry.createProxy("TwoKeyUpgradableExchange", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the TwoKeyUpgradableExchange contract is : ' + proxy);

                        const twoKeyUpgradableExchange = fileObject.TwoKeyUpgradableExchange || {};
                        twoKeyUpgradableExchange[networkId] = {
                            'address' : TwoKeyUpgradableExchange.address,
                            'Proxy' : proxy,
                            'Version' : "1.0",
                            maintainer_address: deployerAddress
                        };

                        fileObject['TwoKeyUpgradableExchange'] = twoKeyUpgradableExchange;
                        proxyAddressTwoKeyUpgradableExchange = proxy;
                        fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                        resolve(proxy);
                    } catch (e) {
                        reject(e);
                    }
                });
            }))
            .then(() => deployer.deploy(TwoKeyEconomy,proxyAddressTwoKeyAdmin, TwoKeySingletonesRegistry.address))
            .then(() => TwoKeyEconomy.deployed())
            .then(async () => {
                await new Promise(async (resolve, reject) => {
                    console.log('... Setting Initial params in all singletone proxy contracts');
                    try {
                        /**
                         * Setting initial parameters in event source and twoKeyRegistry contract
                         */
                        await EventSource.at(proxyAddressTwoKeyEventSource).setInitialParams
                        (
                            proxyAddressTwoKeyAdmin,
                            [],
                            proxyAddressTwoKeyRegistry
                        );
                        await TwoKeyExchangeRateContract.at(proxyAddressTwoKeyExchange).setInitialParams
                        (

                            maintainerAddresses,
                            proxyAddressTwoKeyAdmin
                        );
                        await TwoKeyUpgradableExchange.at(proxyAddressTwoKeyUpgradableExchange).setInitialParams
                        (
                            95,
                            proxyAddressTwoKeyAdmin,
                            TwoKeyEconomy.address,
                            proxyAddressTwoKeyExchange,
                            []
                        );
                        await TwoKeyAdmin.at(proxyAddressTwoKeyAdmin).setInitialParams
                        (
                            TwoKeyCongress.address,
                            TwoKeyEconomy.address,
                            proxyAddressTwoKeyUpgradableExchange,
                            proxyAddressTwoKeyRegistry,
                            proxyAddressTwoKeyEventSource
                        );
                        let txHash = await TwoKeyRegistry.at(proxyAddressTwoKeyRegistry).setInitialParams
                        (
                            proxyAddressTwoKeyEventSource,
                            proxyAddressTwoKeyAdmin,
                            maintainerAddresses,
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .then(async () => {
                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('Transfering 2key-tokens');
                        let txHash = await TwoKeyAdmin.at(proxyAddressTwoKeyAdmin).transfer2KeyTokens(proxyAddressTwoKeyUpgradableExchange, 10000000000000000000);
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
    } else if (deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.link(Call, TwoKeyPlasmaEvents);
        deployer.deploy(TwoKeyPlasmaEvents)
            .then(() => deployer.deploy(TwoKeyPlasmaSingletoneRegistry, [], '0x0')) //adding empty admin address
            .then(() => TwoKeyPlasmaSingletoneRegistry.deployed().then(async (registry) => {
                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyPlasmaEvents to Plasma Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyPlasmaEvents to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyPlasmaEvents", "1.0", TwoKeyPlasmaEvents.address);
                        let { logs } = await registry.createProxy("TwoKeyPlasmaEvents", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the TwoKeyPlasmaEvents is : ' + proxy);
                        const twoKeyPlasmaEvents = fileObject.TwoKeyPlasmaEvents || {};

                        twoKeyPlasmaEvents[networkId] = {
                            'address': TwoKeyPlasmaEvents.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: maintainerAddresses,
                        };

                        fileObject['TwoKeyPlasmaEvents'] = twoKeyPlasmaEvents;
                        proxyAddressTwoKeyPlasmaEvents = proxy;
                        fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                        resolve(proxy);
                    } catch (e) {
                        reject(e);
                    }
                })
            }))
            .then(async () => {
                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in plasma contract on plasma network', maintainerAddresses);
                        let txHash = await TwoKeyPlasmaEvents.at(proxyAddressTwoKeyPlasmaEvents).setInitialParams
                        (
                            //TODO: Paste here real maintainer address on plasma network
                            [maintainerAddresses]
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })
            .then(() => true)
            .catch((err) => {
                console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
            });
    }
};
