const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const TwoKeyCongressMembersRegistry = artifacts.require('TwoKeyCongressMembersRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyBaseReputationRegistry = artifacts.require('TwoKeyBaseReputationRegistry');
const TwoKeyParticipationMiningPool = artifacts.require('TwoKeyParticipationMiningPool');
const TwoKeyDeepFreezeTokenPool = artifacts.require('TwoKeyDeepFreezeTokenPool');
const TwoKeyNetworkGrowthFund = artifacts.require('TwoKeyNetworkGrowthFund');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyFactory = artifacts.require('TwoKeyFactory');
const KyberNetworkTestMockContract = artifacts.require('KyberNetworkTestMockContract');
const TwoKeyMaintainersRegistry = artifacts.require('TwoKeyMaintainersRegistry');
const TwoKeySignatureValidator = artifacts.require('TwoKeySignatureValidator');
const TwoKeyParticipationPaymentsManager = artifacts.require('TwoKeyParticipationPaymentsManager');

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
const TwoKeyParticipationMiningPoolStorage = artifacts.require('TwoKeyParticipationMiningPoolStorage');
const TwoKeyDeepFreezeTokenPoolStorage = artifacts.require('TwoKeyDeepFreezeTokenPoolStorage');
const TwoKeyNetworkGrowthFundStorage = artifacts.require('TwoKeyNetworkGrowthFundStorage');
const TwoKeyRegistryStorage = artifacts.require('TwoKeyRegistryStorage');
const TwoKeySignatureValidatorStorage = artifacts.require('TwoKeySignatureValidatorStorage');
const TwoKeyParticipationPaymentsManagerStorage = artifacts.require('TwoKeyParticipationPaymentsManagerStorage');

const TwoKeyPlasmaCongress = artifacts.require('TwoKeyPlasmaCongress');
const TwoKeyPlasmaCongressMembersRegistry = artifacts.require('TwoKeyPlasmaCongressMembersRegistry');
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

const proxyFile = path.join(__dirname, '../build/proxyAddresses.json');
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
        TwoKeyParticipationMiningPoolStorage,
        TwoKeyDeepFreezeTokenPoolStorage,
        TwoKeyBaseReputationRegistryStorage,
        TwoKeyNetworkGrowthFundStorage,
        TwoKeyCampaignValidatorStorage,
        TwoKeyFactoryStorage,
        TwoKeyMaintainersRegistryStorage,
        TwoKeySignatureValidatorStorage,
        TwoKeyParticipationPaymentsManagerStorage
    };

    let contractLogicArtifacts = {
         TwoKeyUpgradableExchange,
         TwoKeyAdmin,
         TwoKeyEventSource,
         TwoKeyRegistry,
         TwoKeyExchangeRateContract,
         TwoKeyParticipationMiningPool,
         TwoKeyDeepFreezeTokenPool,
         TwoKeyBaseReputationRegistry,
         TwoKeyNetworkGrowthFund,
         TwoKeyCampaignValidator,
         TwoKeyFactory,
         TwoKeyMaintainersRegistry,
         TwoKeySignatureValidator,
         TwoKeyParticipationPaymentsManager
    };

    let nonUpgradableContractArtifactsMainchain = {
        TwoKeyEconomy,
        TwoKeyCongress,
        TwoKeyCongressMembersRegistry
    };

    let nonUpgradableContractArtifactsPlasma = {
        TwoKeyPlasmaCongress,
        TwoKeyPlasmaCongressMembersRegistry
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
        } else if (nonUpgradableContractArtifactsMainchain[contractName]) {
            return nonUpgradableContractArtifactsMainchain[contractName];
        } else if (nonUpgradableContractArtifactsPlasma[contractName]) {
            return nonUpgradableContractArtifactsPlasma[contractName];
        } else {
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
            .then(() => deployer.deploy(TwoKeyEconomy, TwoKeySingletonesRegistry.address))
            .then(() => TwoKeyEconomy.deployed())
            .then(async () => {

                let registry = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address);
                let nonUpgradableSingletones = Object.keys(nonUpgradableContractArtifactsMainchain);
                /* eslint-disable no-await-in-loop */
                for(let i=0; i<nonUpgradableSingletones.length; i++) {
                    /**
                     * Here we will add congress contract to the registry
                     */
                    await new Promise(async (resolve, reject) => {
                        try {
                            let contractName = nonUpgradableSingletones[i];
                            let contract = getContractPerName(contractName);
                            console.log('Adding ' + contractName + 'to the registry as non-upgradable contract');
                            let txHash = registry.addNonUpgradableContractToAddress(nonUpgradableSingletones[i], contract.address);
                            resolve(txHash);
                        } catch (e) {
                            reject(e);
                        }
                    });
                }
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
        .then(async () => {
            let registry = await TwoKeyPlasmaSingletoneRegistry.at(TwoKeyPlasmaSingletoneRegistry.address);
            let nonUpgradableSingletones = Object.keys(nonUpgradableContractArtifactsPlasma);


            /* eslint-disable no-await-in-loop */
            for(let i=0; i<nonUpgradableSingletones.length; i++) {
                /**
                 * Here we will add congress contract to the registry
                 */
                await new Promise(async (resolve, reject) => {
                    try {
                        let contractName = nonUpgradableSingletones[i];
                        let contract = getContractPerName(contractName);
                        console.log('Adding ' + contractName + ' on address: ' + contract.address + 'to the registry as non-upgradable contract');
                        let txHash = registry.addNonUpgradableContractToAddress(contractName, contract.address);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
            }
        })
        .then(() => true);
    }
};
