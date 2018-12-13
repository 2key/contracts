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
    let proxyAddressTwoKeyCongress;


    /**
     * Initial variables we need for contracts initial state
     */
    let adminInstance;
    let initialCongressMembers = [
        '0x4216909456e770FFC737d987c273a0B8cE19C13e', // Eitan
        '0x5e2B2b278445AaA649a6b734B0945Bd9177F4F03', // Kiki
    ];
    let maintainerAddress = (deployer.network.startsWith('ropsten') || deployer.network.startsWith('rinkeby') || deployer.network.startsWith('public.')) ? '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f' : '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';
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
            .then(async (instance) => {
                /**
                 * Assign admin instance to globaly visible variable
                 * @type {T}
                 */
                adminInstance = instance;
                console.log("ADMIN ADDRESS: " + TwoKeyAdmin.address);
            })
            .then(() => deployer.deploy(TwoKeyEconomy, TwoKeyAdmin.address))
            .then(() => deployer.deploy(TwoKeyExchangeContract, [maintainerAddress], TwoKeyAdmin.address))
            .then(() => TwoKeyExchangeContract.deployed())
            .then(() => deployer.deploy(EventSource))
            .then(() => deployer.deploy(TwoKeyRegistry)
            .then(() => TwoKeyRegistry.deployed())
            //TODO: revert back to proxy address of exchange once it's ready
            .then(() => deployer.deploy(TwoKeyUpgradableExchange, 95, TwoKeyAdmin.address, TwoKeyEconomy.address, TwoKeyExchangeContract.address, [maintainerAddress]))
            .then(() => TwoKeyUpgradableExchange.deployed())
            .then(() => deployer.deploy(TwoKeySingletonesRegistry, [maintainerAddress], TwoKeyAdmin.address))
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

                        twoKeyReg[networkId] = {
                            'address': TwoKeyRegistry.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: maintainerAddress,
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
                            maintainer_address: maintainerAddress,
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
                        console.log('... Adding TwoKeyExchangeContract to Proxy registry as valid implementation');
                        /**
                         * Adding EventSource to the registry, deploying 1st proxy for that 1.0 version of EventSource
                         */
                        let txHash = await registry.addVersion("TwoKeyExchangeContract", "1.0", TwoKeyExchangeContract.address);
                        let { logs } = await registry.createProxy("TwoKeyExchangeContract", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the TwoKeyExchangeContract is : ' + proxy);

                        const twoKeyExchange = fileObject.TwoKeyExchange || {};

                        twoKeyExchange[networkId] = {
                            'address': TwoKeyExchangeContract.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: maintainerAddress,
                        };
                        // fileObject['TwoKeyExchangeContract'] = twoKeyExchange;
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

                        const twoKeyAdmin = fileObject.TwoKeyAdmin || {};
                        twoKeyAdmin[networkId] = {
                            'address': TwoKeyAdmin.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: maintainerAddress
                        };

                        // fileObject['TwoKeyAdmin'] = twoKeyAdmin;
                        proxyAddressTwoKeyAdmin = proxy;

                        resolve(proxy);

                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyCongress contract to proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyCongress to the registry, deploying 1st proxy for that 1.0 version of TwoKeyCongress
                         */
                        let txHash = await registry.addVersion("TwoKeyCongress", "1.0", TwoKeyCongress.address);
                        let { logs } = await registry.createProxy("TwoKeyCongress", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the TwoKeyCongress contract is : ' + proxy);

                        const twoKeyCongress = fileObject.TwoKeyCongress || {};
                        twoKeyCongress[networkId] = {
                            'address' : TwoKeyCongress.address,
                            'Proxy' : proxy,
                            'Version' : "1.0",
                            maintainer_address: maintainerAddress
                        };

                        // fileObject['TwoKeyCongress'] = twoKeyCongress;
                        proxyAddressTwoKeyCongress = proxy;
                        fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                        resolve(proxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    console.log('... Setting Initial params in all singletone proxy contracts');
                    try {
                        /**
                         * Setting initial parameters in event source and twoKeyRegistry contract
                         */
                        await EventSource.at(proxyAddressTwoKeyEventSource).setInitialParams
                        (
                            TwoKeyAdmin.address
                        );
                        //TODO: revert back to proxy address of exchange once it's ready
                        // await TwoKeyExchangeContract.at(TwoKeyExchangeContract.address).setInitialParams
                        // (
                        //     [maintainerAddress],
                        //     TwoKeyAdmin.address
                        // );
                        //TODO: Change to proxy addresses once it's all ready
                        await TwoKeyAdmin.at(adminInstance.address).setInitialParams
                        (
                            TwoKeyCongress.address,
                            TwoKeyEconomy.address,
                            TwoKeyUpgradableExchange.address,
                            proxyAddressTwoKeyRegistry,
                            proxyAddressTwoKeyEventSource
                        );

                        //TODO: Change to proxy addresses once it's all ready
                        await TwoKeyCongress.at(TwoKeyCongress.address).setInitialParams
                        (
                            50,
                            initialCongressMembers,
                            votingPowers
                        );

                        let txHash = await TwoKeyRegistry.at(proxyAddressTwoKeyRegistry).setInitialParams
                        (
                            proxyAddressTwoKeyEventSource,
                            TwoKeyAdmin.address,
                            maintainerAddress
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            }))
            .then(() => EventSource.deployed().then(async () => {
                console.log("... Adding TwoKeyRegistry to EventSource");
                await new Promise(async (resolve, reject) => {
                    try {
                        let txHash = await EventSource.at(proxyAddressTwoKeyEventSource).addTwoKeyReg(proxyAddressTwoKeyRegistry).then(() => true);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
                console.log("Added TwoKeyReg: " + proxyAddressTwoKeyRegistry + "  to EventSource : " + proxyAddressTwoKeyEventSource + "!")
            }))
            .then(async () => {
                await new Promise(async (resolve, reject) => {
                    try {
                        //TODO: Once it's ready move this address to the actual admin proxy address
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
    } else if (deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.link(Call, TwoKeyPlasmaEvents);
        deployer.deploy(TwoKeyPlasmaEvents);
    }
};
