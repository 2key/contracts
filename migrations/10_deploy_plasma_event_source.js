const TwoKeyPlasmaEventSource = artifacts.require('TwoKeyPlasmaEventSource');
const TwoKeyPlasmaEventSourceStorage = artifacts.require('TwoKeyPlasmaEventSourceStorage');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');


const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/proxyAddresses.json');

const INITIAL_VERSION_OF_ALL_SINGLETONS = "1.0.0";

let fileObject = {};
if (fs.existsSync(proxyFile)) {
    fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
}

/**
 * Script which will be called only once to add new contract to the system
 * @param deployer
 */

module.exports = function deploy(deployer) {

    const { network_id } = deployer;

    let proxyLogic;
    let proxyStorage;

    if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.deploy(TwoKeyPlasmaEventSource)
            .then(() => TwoKeyPlasmaEventSource.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaEventSourceStorage))
            .then(() => TwoKeyPlasmaEventSourceStorage.deployed())
            .then(async () => {
                await new Promise(async (resolve, reject) => {
                    try {
                        let registry = await TwoKeyPlasmaSingletoneRegistry.at(TwoKeyPlasmaSingletoneRegistry.address);

                        console.log('-----------------------------------------------------------------------------------');
                        console.log('... Adding TwoKeyPlasmaEventSource to Proxy registry as valid implementation');
                        let contractName = "TwoKeyPlasmaEventSource";
                        let contractStorageName = "TwoKeyPlasmaEventSourceStorage";

                        let txHash = await registry.addVersionDuringCreation(
                            contractName,
                            contractStorageName,
                            TwoKeyPlasmaEventSource.address,
                            TwoKeyPlasmaEventSourceStorage.address,
                            INITIAL_VERSION_OF_ALL_SINGLETONS
                        );

                        let { logs } = await registry.createProxy(
                            contractName,
                            contractStorageName,
                            INITIAL_VERSION_OF_ALL_SINGLETONS
                        );

                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;

                        proxyLogic = logicProxy;
                        proxyStorage = storageProxy;

                        const jsonObject = fileObject[contractName] || {};
                        jsonObject[network_id] = {
                            'implementationAddressLogic': TwoKeyPlasmaFactory.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyPlasmaFactoryStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        fileObject[contractName] = jsonObject;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });
                fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
            })
            .then(async () => {
                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in TwoKeyPlasmaEventSource contract on plasma network');
                        let instance = await TwoKeyPlasmaEventSource.at(proxyLogic);
                        let txHash = instance.setInitialParams
                        (
                            TwoKeyPlasmaSingletoneRegistry.address,
                            proxyStorage,
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })
            .then(() => true);
    }
};


