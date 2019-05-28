const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const Proxy = artifacts.require('UpgradeabilityProxy');
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const Call = artifacts.require('Call');

const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');


module.exports = function deploy(deployer) {
    const { network_id } = deployer;
    let found = false;

    let isRegistry = false;
    let isEventSource = false;
    let isTwoKeyExchangeContract = false;
    let isTwoKeyAdmin = false;
    let isTwoKeyCongress = false;
    let isTwoKeyPlasmaEvents = false;
    let isTwoKeyUpgradableExchange = false;

    /**
     * Determining which contract we want to update
     */
    process.argv.forEach((argument) => {
        if (argument == 'update') {
            console.log('Works');
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
        else if (argument == 'TwoKeyUpgradableExchange') {
            isTwoKeyUpgradableExchange = true;
        }
        else if (argument == 'TwoKeyPlasmaEvents') {
            console.log('Works2');
            isTwoKeyPlasmaEvents = true;
        }
    });

    /**
     * If network is not found or contract is not found return immediately
     */
    if(!found) {
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

                                let v = parseInt(twoKeyReg[network_id].Version.substr(-1)) + 1;
                                twoKeyReg[network_id].Version = twoKeyReg[network_id].Version.substr(0, twoKeyReg[network_id].Version.length - 1) + v.toString();

                                console.log('New version : ' + twoKeyReg[network_id].Version);
                                let txHash = await registry.addVersion("TwoKeyRegistry", twoKeyReg[network_id].Version, TwoKeyRegistry.address);

                                console.log('... Upgrading proxy to new version');
                                txHash = await Proxy.at(twoKeyReg[network_id].Proxy).upgradeTo("TwoKeyRegistry", "1.1");
                                twoKeyReg[network_id].address = lastTwoKeyRegistryAddress;
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

                                    let v = parseInt(twoKeyEventSource[network_id].Version.substr(-1)) + 1;
                                    twoKeyEventSource[network_id].Version = twoKeyEventSource[network_id].Version.substr(0, twoKeyEventSource[network_id].Version.length - 1) + v.toString();
                                    console.log('New version : ' + twoKeyEventSource[network_id].Version);
                                    let txHash = await registry.addVersion("TwoKeyEventSource", twoKeyEventSource[network_id].Version, EventSource.address);

                                    console.log('... Upgrading proxy to new version');
                                    txHash = await Proxy.at(twoKeyEventSource[network_id].Proxy).upgradeTo("TwoKeyEventSource", twoKeyEventSource[network_id].Version);
                                    twoKeyEventSource[network_id].address = lastEventSourceAddress;

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

                                let v = parseInt(twoKeyExchange[network_id].Version.substr(-1)) + 1;
                                twoKeyExchange[network_id].Version = twoKeyExchange[network_id].Version.substr(0, twoKeyExchange[network_id].Version.length - 1) + v.toString();
                                console.log('New version : ' + twoKeyExchange[network_id].Version);
                                let txHash = await registry.addVersion("TwoKeyExchangeRateContract", twoKeyExchange[network_id].Version, TwoKeyExchangeRateContract.address);

                                console.log('... Upgrading proxy to new version');
                                txHash = await Proxy.at(twoKeyExchange[network_id].Proxy).upgradeTo("TwoKeyExchangeRateContract", twoKeyExchange[network_id].Version);
                                twoKeyExchange[network_id].address = lastTwoKeyExchangeContract;

                                fileObject['TwoKeyExchangeRateContract'] = twoKeyExchange;
                                fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                                resolve(txHash);
                            } catch (e) {
                                reject(e);
                            }
                        })
                    })
                )
        } else if (isTwoKeyUpgradableExchange) {
            /**
             * If contract we're updating is TwoKeyUpgradableExchange (arugment) this 'subscript' will be executed
             */
            let lastTwoKeyUpgradableExchangeContract;
            console.log('TwoKeyUpgradableExchange will be updated now.');
            deployer.deploy(TwoKeyUpgradableExchange)
                .then(() => TwoKeyUpgradableExchange.deployed()
                    .then((twoKeyUpgradableExchangeInstance) => {
                        lastTwoKeyUpgradableExchangeContract = twoKeyUpgradableExchangeInstance.address;
                    })
                    .then(() => TwoKeySingletonesRegistry.deployed())
                    .then(async(registry) => {
                        await new Promise(async(resolve,reject) => {
                            try {
                                console.log('... Adding new version of TwoKeyUpgradableExchange to the registry contract');
                                const twoKeyUpgradableExchange = fileObject.TwoKeyUpgradableExchange || {};
                                let v = parseInt(twoKeyUpgradableExchange[network_id].Version.substr(-1)) + 1;
                                twoKeyUpgradableExchange[network_id].Version = twoKeyUpgradableExchange[network_id].Version.substr(0, twoKeyUpgradableExchange[network_id].Version.length - 1) + v.toString();
                                console.log('New version : ' + twoKeyUpgradableExchange[network_id].Version);
                                let txHash = await registry.addVersion("TwoKeyUpgradableExchange", "1.6", TwoKeyUpgradableExchange.address);

                                console.log('... Upgrading proxy to new version');
                                // txHash = await Proxy.at(twoKeyUpgradableExchange[network_id].Proxy).upgradeTo("TwoKeyUpgradableExchange", twoKeyUpgradableExchange[network_id].Version);
                                txHash = await Proxy.at(twoKeyUpgradableExchange[network_id].Proxy).upgradeTo("TwoKeyUpgradableExchange", "1.5");
                                twoKeyUpgradableExchange[network_id].address = lastTwoKeyUpgradableExchangeContract;

                                fileObject['TwoKeyUpgradableExchange'] = twoKeyUpgradableExchange;
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
                                let v = parseInt(twoKeyAdmin[network_id].Version.substr(-1)) + 1;
                                twoKeyAdmin[network_id].Version = twoKeyAdmin[network_id].Version.substr(0, twoKeyAdmin[network_id].Version.length - 1) + v.toString();
                                console.log('New version : ' + twoKeyAdmin[network_id].Version);
                                let txHash = await registry.addVersion("TwoKeyAdmin", twoKeyAdmin[network_id].Version, TwoKeyAdmin.address);

                                console.log('... Upgrading proxy to new version');
                                txHash = await Proxy.at(twoKeyAdmin[network_id].Proxy).upgradeTo("TwoKeyAdmin", twoKeyAdmin[network_id].Version);
                                twoKeyAdmin[network_id].address = lastTwoKeyAdminContract;

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
                               let v = parseInt(twoKeyCongress[network_id].Version.substr(-1)) + 1;
                               twoKeyCongress[network_id].Version = twoKeyCongress[network_id].Version.substr(0, twoKeyCongress[network_id].Version.length - 1) + v.toString();
                               console.log('New version : ' + twoKeyCongress[network_id].Version);
                               let txHash = await registry.addVersion("TwoKeyCongress", twoKeyCongress[network_id].Version, TwoKeyCongress.address);

                               console.log('... Upgrading proxy to new version');
                               txHash = await Proxy.at(twoKeyCongress[network_id].Proxy).upgradeTo("TwoKeyCongress", twoKeyCongress[network_id].Version);
                               twoKeyCongress[network_id].address = lastTwoKeyCongressContract;

                               fileObject['TwoKeyCongress'] = twoKeyCongress;
                               fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                               resolve(txHash);
                           } catch (e) {
                               reject(e);
                           }
                       })
                    })
                )
        } else if (isTwoKeyPlasmaEvents) {
            /**
             * If contract we're updating is TwoKeyPlasmaEvents (argument) this 'subscript' will be executed
             */
            let lastTwoKeyPlasmaEvents;
            console.log('TwoKeyPlasmaEvents contract on plasma network will be updated now', network_id);
            deployer.link(Call, TwoKeyPlasmaEvents);
            deployer.deploy(TwoKeyPlasmaEvents)
            .then(() => TwoKeyPlasmaEvents.deployed()
                .then((twoKeyPlasmaEventsInstance) => {
                    lastTwoKeyPlasmaEvents = twoKeyPlasmaEventsInstance.address;
                })
                .then(() => TwoKeyPlasmaSingletoneRegistry.deployed())
                .then(async(registry) => {
                    await new Promise(async(resolve,reject) => {
                        try {
                            console.log('... Adding new version of TwoKeyPlasmaEvents to Registry on Plasma Network');
                            const twoKeyPlasmaEvents = fileObject.TwoKeyPlasmaEvents || {};
                            let v = parseInt(twoKeyPlasmaEvents[network_id].Version.substr(-1)) + 1;
                            twoKeyPlasmaEvents[network_id].Version = twoKeyPlasmaEvents[network_id].Version.substr(0, twoKeyPlasmaEvents[network_id].Version.length - 1) + v.toString();
                            console.log('New version : ' + twoKeyPlasmaEvents[network_id].Version);
                            //
                            let txHash = await registry.addVersion("TwoKeyPlasmaEvents",twoKeyPlasmaEvents[network_id].Version, TwoKeyPlasmaEvents.address);
                            // let txHash = await registry.addVersion("TwoKeyPlasmaEvents", '1.10', TwoKeyPlasmaEvents.address);

                            console.log('... Upgrading proxy to new version');
                            txHash = await Proxy.at(twoKeyPlasmaEvents[network_id].Proxy).upgradeTo("TwoKeyPlasmaEvents", twoKeyPlasmaEvents[network_id].Version);
                            // txHash = await Proxy.at(twoKeyPlasmaEvents[network_id].Proxy).upgradeTo("TwoKeyPlasmaEvents", '1.10');
                            twoKeyPlasmaEvents[network_id].address = lastTwoKeyPlasmaEvents;

                            fileObject['TwoKeyPlasmaEvents'] = twoKeyPlasmaEvents;
                            fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                            resolve(txHash);
                        } catch (e) {
                            reject(e);
                        }
                    })
                })
            )
            .then(() => true);
        }
    } else {
        console.log('Argument is not found - contracts will not be updated!');
    }
};
