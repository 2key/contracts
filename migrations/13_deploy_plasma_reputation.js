const TwoKeyPlasmaReputationRegistry = artifacts.require('TwoKeyPlasmaReputationRegistry');
const TwoKeyPlasmaReputationRegistryStorage = artifacts.require('TwoKeyPlasmaReputationRegistryStorage');
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

    if(deployer.network.startsWith('private') || deployer.network.startsWith('plasma')) {
        deployer.deploy(TwoKeyPlasmaReputationRegistry)
            .then(() => TwoKeyPlasmaReputationRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaReputationRegistryStorage))
            .then(() => TwoKeyPlasmaReputationRegistryStorage.deployed())
            .then(async () => {
                await new Promise(async (resolve, reject) => {
                    try {
                        let registry = await TwoKeyPlasmaSingletoneRegistry.at(TwoKeyPlasmaSingletoneRegistry.address);

                        console.log('-----------------------------------------------------------------------------------');
                        console.log('... Adding TwoKeyPlasmaReputationRegistry to Proxy registry as valid implementation');
                        let contractName = "TwoKeyPlasmaReputationRegistry";
                        let contractStorageName = "TwoKeyPlasmaReputationRegistryStorage";

                        let txHash = await registry.addVersionDuringCreation(
                            contractName,
                            contractStorageName,
                            TwoKeyPlasmaReputationRegistry.address,
                            TwoKeyPlasmaReputationRegistryStorage.address,
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
                            'implementationAddressLogic': TwoKeyPlasmaReputationRegistry.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyPlasmaReputationRegistryStorage.address,
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
                        console.log('Setting initial params in TwoKeyPlasmaReputationRegistry contract on plasma network');
                        let instance = await TwoKeyPlasmaReputationRegistry.at(proxyLogic);
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


