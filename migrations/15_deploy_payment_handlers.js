const TwoKeyPlasmaBudgetCampaignsPaymentsHandler = artifacts.require('TwoKeyPlasmaBudgetCampaignsPaymentsHandler');
const TwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage = artifacts.require('TwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage');

const TwoKeyBudgetCampaignsPaymentsHandler = artifacts.require('TwoKeyBudgetCampaignsPaymentsHandler');
const TwoKeyBudgetCampaignsPaymentsHandlerStorage = artifacts.require('TwoKeyBudgetCampaignsPaymentsHandlerStorage');

const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
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

    if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        console.log('Deploying private (plasma)  version of TwoKeyPlasmaBudgetCampaignsPaymentsHandler contract');
        deployer.deploy(TwoKeyPlasmaBudgetCampaignsPaymentsHandler)
            .then(() => TwoKeyPlasmaBudgetCampaignsPaymentsHandler.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage))
            .then(() => TwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage.deployed())
            .then(async () => {
                await new Promise(async (resolve, reject) => {
                    try {
                        let registry = await TwoKeyPlasmaSingletoneRegistry.at(TwoKeyPlasmaSingletoneRegistry.address);

                        console.log('-----------------------------------------------------------------------------------');
                        console.log('... Adding TwoKeyPlasmaBudgetCampaignsPaymentsHandler to Proxy registry as valid implementation');
                        let contractName = "TwoKeyPlasmaBudgetCampaignsPaymentsHandler";
                        let contractStorageName = "TwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage";

                        let txHash = await registry.addVersionDuringCreation(
                            contractName,
                            contractStorageName,
                            TwoKeyPlasmaBudgetCampaignsPaymentsHandler.address,
                            TwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage.address,
                            INITIAL_VERSION_OF_ALL_SINGLETONS
                        );

                        let {logs} = await registry.createProxy(
                            contractName,
                            contractStorageName,
                            INITIAL_VERSION_OF_ALL_SINGLETONS
                        );

                        let {logicProxy, storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;

                        proxyLogic = logicProxy;
                        proxyStorage = storageProxy;

                        const jsonObject = fileObject[contractName] || {};
                        jsonObject[network_id] = {
                            'implementationAddressLogic': TwoKeyPlasmaBudgetCampaignsPaymentsHandler.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyPlasmaBudgetCampaignsPaymentsHandlerStorage.address,
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
                        console.log('Setting initial params in TwoKeyPlasmaBudgetCampaignsPaymentsHandler contract on plasma network');
                        let instance = await TwoKeyPlasmaBudgetCampaignsPaymentsHandler.at(proxyLogic);
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
    } else if(deployer.network.startsWith('public') || deployer.network.startsWith('dev-local')) {
        console.log('Deploying public version of TwoKeyBudgetCampaignsPaymentsHandler contract');

        // deployer.deploy(TwoKeyBudgetCampaignsPaymentsHandler)
        //     .then(() => TwoKeyBudgetCampaignsPaymentsHandler.deployed())
        //     .then(() => deployer.deploy(TwoKeyBudgetCampaignsPaymentsHandlerStorage))
        //     .then(() => TwoKeyBudgetCampaignsPaymentsHandlerStorage.deployed())
        deployer.then(async () => {
            await new Promise(async (resolve, reject) => {
                try {
                    let registry = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address);

                    console.log('-----------------------------------------------------------------------------------');
                    console.log('... Adding TwoKeyBudgetCampaignsPaymentsHandler to Proxy registry as valid implementation');
                    let contractName = "TwoKeyBudgetCampaignsPaymentsHandler";
                    let contractStorageName = "TwoKeyBudgetCampaignsPaymentsHandlerStorage";

                    // let txHash = await registry.addVersionDuringCreation(
                    //     contractName,
                    //     contractStorageName,
                    //     TwoKeyBudgetCampaignsPaymentsHandler.address,
                    //     TwoKeyBudgetCampaignsPaymentsHandlerStorage.address,
                    //     INITIAL_VERSION_OF_ALL_SINGLETONS
                    // );

                    let {logs} = await registry.createProxy(
                        contractName,
                        contractStorageName,
                        INITIAL_VERSION_OF_ALL_SINGLETONS
                    );

                    let {logicProxy, storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;

                    proxyLogic = logicProxy;
                        proxyStorage = storageProxy;

                        const jsonObject = fileObject[contractName] || {};
                        jsonObject[network_id] = {
                            'implementationAddressLogic': TwoKeyBudgetCampaignsPaymentsHandler.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyBudgetCampaignsPaymentsHandlerStorage.address,
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
                        console.log('Setting initial params in TwoKeyBudgetCampaignsPaymentsHandler contract on plasma network');
                        let instance = await TwoKeyBudgetCampaignsPaymentsHandler.at(proxyLogic);
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


