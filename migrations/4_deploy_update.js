const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const Proxy = artifacts.require('UpgradeabilityProxy');
const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');


module.exports = function deploy(deployer) {
    let maintainerAddress = (deployer.network.startsWith('ropsten') || deployer.network.startsWith('rinkeby') || deployer.network.startsWith('public.')) ? '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f' : '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';

    /**
     * Is argument 'update' is found
     * @type {boolean}
     */
    let found = false;

    /**
     * Is Registry contract the one we are updating
     * @type {boolean}
     */
    let isRegistry = false;

    /**
     * Is eventSource contract the one we are updating
     * @type {boolean}
     */
    let isEventSource = false;

    /**
     * Is twoKeyExchangeContract the one we are updating
     * @type {boolean}
     */
    let isTwoKeyExchangeContract = false;

    /**
     * Is twoKeyAdminContract the one we are updating
     * @type {boolean}
     */
    let isTwoKeyAdmin = false;

    /**
     * Is twoKeyCongress contract the one we are updating
     * @type {boolean}
     */
    let isTwoKeyCongress = false;

    /**
     * Determining which contract we want to update
     */
    process.argv.forEach((argument) => {
        if (argument == 'update') {
            found = true
        }
        else if (argument == 'TwoKeyRegistry') {
            isRegistry = true;
        }
        else if (argument == 'TwoKeyEventSource') {
            isEventSource = true;
        }
        else if (argument == 'TwoKeyExchangeRateContract') {
            isTwoKeyExchangeContract = true;
        }
        else if (argument == 'TwoKeyAdmin') {
            isTwoKeyAdmin = true;
        }
        else if (argument == 'TwoKeyCongress') {
            isTwoKeyCongress = true;
        }
    });

    /**
     * Determining which network id we're using
     * @type {number}
     */
    let networkId = 0;
    if (deployer.network.startsWith('ropsten')) {
        networkId = 3;
    } else if (deployer.network.startsWith('rinkeby')) {
        networkId = 4;
    } else if (deployer.network.startsWith('public')) {
        networkId = 3;
    } else if (deployer.network.startsWith('dev-local')) {
        networkId = 8086;
    } else if(deployer.network.startsWith('development')) {
        networkId = 'ganache';
    }

    /**
     * If network is not found or contract is not found return immediately
     */
    if(networkId == 0 || found == false) {
        return;
    }

    if(found) {
        let fileObject = {};
        if (fs.existsSync(proxyFile)) {
            fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
        }
        if(isRegistry) {
            /**
             * If contract we're updating is TwoKeyRegistry (argument) this 'subscript' will be executed.
             */
            let lastTwoKeyRegistryAddress;
            console.log('TwoKeyRegistry contract will be updated now.');
            deployer.deploy(TwoKeyRegistry)
                .then(() => TwoKeyRegistry.deployed()
                .then(async (twoKeyRegistryInstance) => {
                    lastTwoKeyRegistryAddress = twoKeyRegistryInstance.address;
                })
                .then(() => TwoKeySingletonesRegistry.deployed()
                    .then(async (registry) => {
                        await new Promise(async (resolve, reject) => {
                            try {
                                console.log('... Adding new version of TwoKeyRegistry to the registry contract');
                                const twoKeyReg = fileObject.TwoKeyRegistry || {};

                                let v = parseInt(twoKeyReg[networkId.toString()].Version.substr(-1)) + 1;
                                twoKeyReg[networkId.toString()].Version = twoKeyReg[networkId.toString()].Version.substr(0, twoKeyReg[networkId.toString()].Version.length - 1) + v.toString();

                                console.log('New version : ' + twoKeyReg[networkId.toString()].Version);
                                let txHash = await registry.addVersion("TwoKeyRegistry", twoKeyReg[networkId.toString()].Version, TwoKeyRegistry.address);

                                console.log('... Upgrading proxy to new version');
                                txHash = await Proxy.at(twoKeyReg[networkId.toString()].Proxy).upgradeTo("TwoKeyRegistry", "1.1");
                                twoKeyReg[networkId.toString()].address = lastTwoKeyRegistryAddress;
                                fileObject['TwoKeyRegistry'] = twoKeyReg;
                                fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                                resolve(txHash);
                            } catch (e) {
                                reject(e);
                            }
                        })
                    }
                )))
        } else if (isEventSource) {
            /**
             * If contract we're updating is TwoKeyEventSource (argument) this 'subscript' will be executed!
             */
            let lastEventSourceAddress;
            console.log('TwoKeyEventSource will be updated now.');
            deployer.deploy(EventSource)
                .then(() => EventSource.deployed()
                .then((eventSourceInstance) => {
                    lastEventSourceAddress = eventSourceInstance.address;
                })
                .then(() => TwoKeySingletonesRegistry.deployed())
                        .then(async(registry) => {
                            await new Promise(async(resolve,reject) => {
                                try {
                                    console.log('... Adding new version of TwoKeyEventSource to the registry contract');
                                    const twoKeyEventSource = fileObject.TwoKeyEventSource || {};

                                    let v = parseInt(twoKeyEventSource[networkId.toString()].Version.substr(-1)) + 1;
                                    twoKeyEventSource[networkId.toString()].Version = twoKeyEventSource[networkId.toString()].Version.substr(0, twoKeyEventSource[networkId.toString()].Version.length - 1) + v.toString();
                                    console.log('New version : ' + twoKeyEventSource[networkId.toString()].Version);
                                    let txHash = await registry.addVersion("TwoKeyEventSource", twoKeyEventSource[networkId.toString()].Version, EventSource.address);

                                    console.log('... Upgrading proxy to new version');
                                    txHash = await Proxy.at(twoKeyEventSource[networkId.toString()].Proxy).upgradeTo("TwoKeyEventSource", twoKeyEventSource[networkId.toString()].Version);
                                    twoKeyEventSource[networkId.toString()].address = lastEventSourceAddress;

                                    fileObject['TwoKeyEventSource'] = twoKeyEventSource;
                                    fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                                    resolve(txHash);
                                } catch (e) {
                                    reject(e);
                                }
                            })
                        })

                )
        } else if(isTwoKeyExchangeContract) {
            /**
             * If contract we're updating is TwoKeyExchangeRateContract (argument) this 'subscript' will be executed!
             */
            let lastTwoKeyExchangeContract;
            console.log('TwoKeyExchangeRateContract will be updated now.');
            deployer.deploy(TwoKeyExchangeRateContract)
                .then(() => TwoKeyExchangeRateContract.deployed()
                    .then((twoKeyExchangeInstance) => {
                        lastTwoKeyExchangeContract = twoKeyExchangeInstance.address;
                    })
                    .then(() => TwoKeySingletonesRegistry.deployed())
                    .then(async(registry) => {
                        await new Promise(async(resolve,reject) => {
                            try {
                                console.log('... Adding new version of TwoKeyExchangeRateContract to the registry contract');
                                const twoKeyExchange = fileObject.ITwoKeyExchangeRateContract || {};

                                let v = parseInt(twoKeyExchange[networkId.toString()].Version.substr(-1)) + 1;
                                twoKeyExchange[networkId.toString()].Version = twoKeyExchange[networkId.toString()].Version.substr(0, twoKeyExchange[networkId.toString()].Version.length - 1) + v.toString();
                                console.log('New version : ' + twoKeyExchange[networkId.toString()].Version);
                                let txHash = await registry.addVersion("TwoKeyExchangeRateContract", twoKeyExchange[networkId.toString()].Version, TwoKeyExchangeRateContract.address);

                                console.log('... Upgrading proxy to new version');
                                txHash = await Proxy.at(twoKeyExchange[networkId.toString()].Proxy).upgradeTo("TwoKeyExchangeRateContract", twoKeyExchange[networkId.toString()].Version);
                                twoKeyExchange[networkId.toString()].address = lastTwoKeyExchangeContract;

                                fileObject['TwoKeyExchangeRateContract'] = twoKeyExchange;
                                fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                                resolve(txHash);
                            } catch (e) {
                                reject(e);
                            }
                        })
                    })
                )
        } else if(isTwoKeyAdmin) {
            /**
             * If contract we're updating is TwoKeyAdmin (arugment) this 'subscript' will be executed
             */
            let lastTwoKeyAdminContract;
            console.log('TwoKeyAdmin will be updated now.');
            deployer.deploy(TwoKeyAdmin)
                .then(() => TwoKeyAdmin.deployed()
                    .then((twoKeyAdminInstance) => {
                        lastTwoKeyAdminContract = twoKeyAdminInstance.address;
                    })
                    .then(() => TwoKeySingletonesRegistry.deployed())
                    .then(async(registry) => {
                        await new Promise(async(resolve,reject) => {
                            try {
                                console.log('... Adding new version of TwoKeyAdminContract to the registry contract');
                                const twoKeyAdmin = fileObject.TwoKeyAdmin || {};
                                let v = parseInt(twoKeyAdmin[networkId.toString()].Version.substr(-1)) + 1;
                                twoKeyAdmin[networkId.toString()].Version = twoKeyAdmin[networkId.toString()].Version.substr(0, twoKeyAdmin[networkId.toString()].Version.length - 1) + v.toString();
                                console.log('New version : ' + twoKeyAdmin[networkId.toString()].Version);
                                let txHash = await registry.addVersion("TwoKeyAdmin", twoKeyAdmin[networkId.toString()].Version, TwoKeyAdmin.address);

                                console.log('... Upgrading proxy to new version');
                                txHash = await Proxy.at(twoKeyAdmin[networkId.toString()].Proxy).upgradeTo("TwoKeyAdmin", twoKeyAdmin[networkId.toString()].Version);
                                twoKeyAdmin[networkId.toString()].address = lastTwoKeyAdminContract;

                                fileObject['TwoKeyAdmin'] = twoKeyAdmin;
                                fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                                resolve(txHash);
                            } catch (e) {
                                reject(e);
                            }
                        })
                    })
                )
        } else if(isTwoKeyCongress) {
            /**
             * If contract we're updating is TwoKeyCongress (argument) this 'subscript' will be executed
             */
            let lastTwoKeyCongressContract;
            console.log('TwoKeyCongress will be updated now.');
            deployer.deploy(TwoKeyCongress)
                .then(() => TwoKeyCongress.deployed()
                    .then((twoKeyCongressInstance) => {
                        lastTwoKeyCongressContract = twoKeyCongressInstance.address;
                    })
                    .then(() => TwoKeySingletonesRegistry.deployed)
                    .then(async(registry) => {
                       await new Promise(async(resolve,reject) => {
                           try {
                               console.log('... Adding new version of TwoKeyCongress to the registry contract');
                               const twoKeyCongress = fileObject.twoKeyCongress || {};
                               let v = parseInt(twoKeyCongress[networkId.toString()].Version.substr(-1)) + 1;
                               twoKeyCongress[networkId.toString()].Version = twoKeyCongress[networkId.toString()].Version.substr(0, twoKeyCongress[networkId.toString()].Version.length - 1) + v.toString();
                               console.log('New version : ' + twoKeyCongress[networkId.toString()].Version);
                               let txHash = await registry.addVersion("TwoKeyCongress", twoKeyCongress[networkId.toString()].Version, TwoKeyCongress.address);

                               console.log('... Upgrading proxy to new version');
                               txHash = await Proxy.at(twoKeyCongress[networkId.toString()].Proxy).upgradeTo("TwoKeyCongress", twoKeyCongress[networkId.toString()].Version);
                               twoKeyCongress[networkId.toString()].address = lastTwoKeyCongressContract;

                               fileObject['TwoKeyCongress'] = twoKeyCongress;
                               fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                               resolve(txHash);
                           } catch (e) {
                               reject(e);
                           }
                       })
                    })
                )
        }
    } else {
        console.log('Argument is not found - contracts will not be updated!');
    }
}