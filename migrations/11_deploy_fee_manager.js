const TwoKeyFeeManager = artifacts.require('TwoKeyFeeManager');
const TwoKeyFeeManagerStorage = artifacts.require('TwoKeyFeeManagerStorage');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');


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

    if(deployer.network.startsWith('public') || deployer.network.startsWith('dev')) {
        deployer.deploy(TwoKeyFeeManager)
            .then(() => TwoKeyFeeManager.deployed())
            .then(() => deployer.deploy(TwoKeyFeeManagerStorage))
            .then(() => TwoKeyFeeManagerStorage.deployed())
            .then(async () => {
                await new Promise(async (resolve, reject) => {
                    try {
                        let registry = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address);

                        console.log('-----------------------------------------------------------------------------------');
                        console.log('... Adding TwoKeyFeeManager to Proxy registry as valid implementation');
                        let contractName = "TwoKeyFeeManager";
                        let contractStorageName = "TwoKeyFeeManagerStorage";

                        let txHash = await registry.addVersion(
                            contractName,
                            INITIAL_VERSION_OF_ALL_SINGLETONS,
                            TwoKeyFeeManager.address
                        );

                        txHash = await registry.addVersion(
                            contractStorageName,
                            INITIAL_VERSION_OF_ALL_SINGLETONS,
                            TwoKeyFeeManagerStorage.address
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
                            'implementationAddressLogic': TwoKeyFeeManager.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyFeeManagerStorage.address,
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
                        console.log('Setting initial params in TwoKeyFeeManager contract on plasma network');
                        let instance = await TwoKeyFeeManager.at(proxyLogic);
                        let txHash = instance.setInitialParams
                        (
                            TwoKeySingletonesRegistry.address,
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


