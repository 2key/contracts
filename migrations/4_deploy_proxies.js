const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyBaseReputationRegistry = artifacts.require('TwoKeyBaseReputationRegistry');
const TwoKeyCommunityTokenPool = artifacts.require('TwoKeyCommunityTokenPool');
const TwoKeyDeepFreezeTokenPool = artifacts.require('TwoKeyDeepFreezeTokenPool');
const TwoKeyLongTermTokenPool = artifacts.require('TwoKeyLongTermTokenPool');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyFactory = artifacts.require('TwoKeyFactory');
const KyberNetworkTestMockContract = artifacts.require('KyberNetworkTestMockContract');
const TwoKeyMaintainersRegistry = artifacts.require('TwoKeyMaintainersRegistry');
const TwoKeySignatureValidator = artifacts.require('TwoKeySignatureValidator');

/**
 * Upgradable singleton storage contracts
 */
const TwoKeyUpgradableExchangeStorage = artifacts.require('TwoKeyUpgradableExchangeStorage');
const TwoKeyCampaignValidatorStorage = artifacts.require('TwoKeyCampaignValidatorStorage');
const TwoKeyEventSourceStorage = artifacts.require("TwoKeyEventSourceStorage");
const TwoKeyAdminStorage = artifacts.require('TwoKeyAdminStorage');
const TwoKeyFactoryStorage = artifacts.require('TwoKeyFactoryStorage');
const TwoKeyMaintainersRegistryStorage = artifacts.require('TwoKeyMaintainersRegistryStorage');
const TwoKeyExchangeRateStorage = artifacts.require('TwoKeyExchangeRateStorage');
const TwoKeyBaseReputationRegistryStorage = artifacts.require('TwoKeyBaseReputationRegistryStorage');
const TwoKeyCommunityTokenPoolStorage = artifacts.require('TwoKeyCommunityTokenPoolStorage');
const TwoKeyDeepFreezeTokenPoolStorage = artifacts.require('TwoKeyDeepFreezeTokenPoolStorage');
const TwoKeyLongTermTokenPoolStorage = artifacts.require('TwoKeyLongTermTokenPoolStorage');
const TwoKeyRegistryStorage = artifacts.require('TwoKeyRegistryStorage');
const TwoKeySignatureValidatorStorage = artifacts.require('TwoKeySignatureValidatorStorage');

const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaEventsStorage = artifacts.require('TwoKeyPlasmaEventsStorage');
const TwoKeyPlasmaRegistry = artifacts.require('TwoKeyPlasmaRegistry');
const TwoKeyPlasmaRegistryStorage = artifacts.require('TwoKeyPlasmaRegistryStorage');
const TwoKeyPlasmaMaintainersRegistryStorage = artifacts.require('TwoKeyPlasmaMaintainersRegistryStorage');
const TwoKeyPlasmaMaintainersRegistry = artifacts.require('TwoKeyPlasmaMaintainersRegistry');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');
const addressesFile = path.join(__dirname, '../configurationFiles/contractNamesToProxyAddresses.json');

module.exports = function deploy(deployer) {
    const { network_id } = deployer;

    let fileObject = {};
    if (fs.existsSync(proxyFile)) {
        fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
    }

    let contractNameToProxyAddress = {};
    if (fs.existsSync(addressesFile)) {
        contractNameToProxyAddress = JSON.parse(fs.readFileSync(addressesFile, { encoding: 'utf8' }));
    }

    let contractStorageArtifacts = {
        TwoKeyUpgradableExchangeStorage,
        TwoKeyAdminStorage,
        TwoKeyEventSourceStorage,
        TwoKeyRegistryStorage,
        TwoKeyExchangeRateStorage,
        TwoKeyBaseReputationRegistryStorage,
        TwoKeyCommunityTokenPoolStorage,
        TwoKeyDeepFreezeTokenPoolStorage,
        TwoKeyLongTermTokenPoolStorage,
        TwoKeyCampaignValidatorStorage,
        TwoKeyFactoryStorage,
        TwoKeyMaintainersRegistryStorage,
        TwoKeySignatureValidatorStorage
    };

    let contractLogicArtifacts = {
         TwoKeyUpgradableExchange,
         TwoKeyAdmin,
         TwoKeyEventSource,
         TwoKeyRegistry,
         TwoKeyExchangeRateContract,
         TwoKeyBaseReputationRegistry,
         TwoKeyCommunityTokenPool,
         TwoKeyDeepFreezeTokenPool,
         TwoKeyLongTermTokenPool,
         TwoKeyCampaignValidator,
         TwoKeyFactory,
         TwoKeyMaintainersRegistry,
         TwoKeySignatureValidator
    };

    let contractLogicArtifactsPlasma = {
        TwoKeyPlasmaEvents,
        TwoKeyPlasmaMaintainersRegistry,
        TwoKeyPlasmaRegistry
    };

    let contractStorageArtifactsPlasma = {
        TwoKeyPlasmaEventsStorage,
        TwoKeyPlasmaMaintainersRegistryStorage,
        TwoKeyPlasmaRegistryStorage,
    };


    /**
     * Function to determine and return truffle build of selected contract
     * @type {function(*)}
     */
    const getContractPerName = ((contractName) => {
        if(contractLogicArtifacts[contractName]) {
            return contractLogicArtifacts[contractName]
        } else if (contractStorageArtifacts[contractName]) {
            return contractStorageArtifacts[contractName]
        } else if (contractLogicArtifactsPlasma[contractName]) {
            return contractLogicArtifactsPlasma[contractName];
        } else if (contractStorageArtifactsPlasma[contractName]) {
            return (contractStorageArtifactsPlasma[contractName]);
        }
        else {
            return "Wrong name";
        }
    });


    const INITIAL_VERSION_OF_ALL_SINGLETONS = "1.0.0";


    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {
            deployer.then(async () => {
                let registry = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address);
                let upgradableLogicContracts = Object.keys(contractLogicArtifacts);
                let upgradableStorageContracts = Object.keys(contractStorageArtifacts);

                /* eslint-disable no-await-in-loop */
                for (let i = 0; i < upgradableLogicContracts.length; i++) {
                    await new Promise(async (resolve, reject) => {
                        try {
                            console.log('-----------------------------------------------------------------------------------');
                            console.log('... Adding ' + upgradableLogicContracts[i] + ' to Proxy registry as valid implementation');
                            let contractName = upgradableLogicContracts[i];
                            let contractStorageName = upgradableStorageContracts[i];

                            let txHash = await registry.addVersionDuringCreation(
                                contractName,
                                contractStorageName,
                                getContractPerName(contractName).address,
                                getContractPerName(contractStorageName).address,
                                INITIAL_VERSION_OF_ALL_SINGLETONS
                            );

                            let { logs } = await registry.createProxy(
                                contractName,
                                contractStorageName,
                                INITIAL_VERSION_OF_ALL_SINGLETONS
                            );

                            let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;

                            const jsonObject = fileObject[contractName] || {};
                            jsonObject[network_id] = {
                                'implementationAddressLogic': getContractPerName(contractName).address,
                                'Proxy': logicProxy,
                                'implementationAddressStorage': getContractPerName(contractStorageName).address,
                                'StorageProxy': storageProxy,
                            };

                            contractNameToProxyAddress[contractName] = logicProxy;
                            contractNameToProxyAddress[contractStorageName] = storageProxy;

                            fileObject[contractName] = jsonObject;
                            resolve(logicProxy);
                        } catch (e) {
                            reject(e);
                        }
                    });
                }
                fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                fs.writeFileSync(addressesFile, JSON.stringify(contractNameToProxyAddress, null, 4));
            })
            .then(() => deployer.deploy(TwoKeyEconomy,contractNameToProxyAddress["TwoKeyAdmin"], TwoKeySingletonesRegistry.address))
            .then(() => TwoKeyEconomy.deployed())
            .then(async () => {

                let registry = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address);
                /**
                 * Here we will add congress contract to the registry
                 */
                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('Adding non-upgradable contracts to the registry');
                        console.log('Adding TwoKeyCongress to the registry as non-upgradable contract');
                        let txHash = registry.addNonUpgradableContractToAddress('TwoKeyCongress', TwoKeyCongress.address);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                /**
                 * Here we will add economy contract to the registry
                 */
                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('Adding TwoKeyEconomy to the registry as non-upgradable contract');
                        let txHash = registry.addNonUpgradableContractToAddress('TwoKeyEconomy', TwoKeyEconomy.address);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .then(() => true)
    } else if (deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.then(async () => {
            let registry = await TwoKeyPlasmaSingletoneRegistry.at(TwoKeyPlasmaSingletoneRegistry.address);

            let upgradableLogicContractsPlasma = Object.keys(contractLogicArtifactsPlasma);
            let upgradableStorageContractsPlasma = Object.keys(contractStorageArtifactsPlasma);

            /* eslint-disable no-await-in-loop */
            for (let i = 0; i < upgradableLogicContractsPlasma.length; i++) {
                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('-----------------------------------------------------------------------------------');
                        console.log('... Adding ' + upgradableLogicContractsPlasma[i] + ' to Proxy registry as valid implementation');
                        let contractName = upgradableLogicContractsPlasma[i];
                        let contractStorageName = upgradableStorageContractsPlasma[i];

                        let txHash = await registry.addVersionDuringCreation(
                            contractName,
                            contractStorageName,
                            getContractPerName(contractName).address,
                            getContractPerName(contractStorageName).address,
                            INITIAL_VERSION_OF_ALL_SINGLETONS
                        );

                        let { logs } = await registry.createProxy(
                            contractName,
                            contractStorageName,
                            INITIAL_VERSION_OF_ALL_SINGLETONS
                        );

                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;

                        const jsonObject = fileObject[contractName] || {};
                        jsonObject[network_id] = {
                            'implementationAddressLogic': getContractPerName(contractName).address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': getContractPerName(contractStorageName).address,
                            'StorageProxy': storageProxy,
                        };

                        contractNameToProxyAddress[contractName] = logicProxy;
                        contractNameToProxyAddress[contractStorageName] = storageProxy;

                        fileObject[contractName] = jsonObject;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });
            }
            fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
            fs.writeFileSync(addressesFile, JSON.stringify(contractNameToProxyAddress, null, 4));
        })
        .then(() => true);
    }
};
