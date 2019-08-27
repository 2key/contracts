const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
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

const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');
const deploymentConfigFile = path.join(__dirname, '../deploymentConfig.json');


module.exports = function deploy(deployer) {
    const { network_id } = deployer;
    /**
     * Read the logicProxy file into fileObject
     * @type {{}}
     */
    let fileObject = {};
    if (fs.existsSync(proxyFile)) {
        fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
    }

    let deploymentObject = {};
    if( fs.existsSync(deploymentConfigFile)) {
        deploymentObject = JSON.parse(fs.readFileSync(deploymentConfigFile, {encoding: 'utf8'}));
    }


    let contractNameToProxyAddress = {};

    /**
     * Define proxyAddress variables for the contracts
     */
    let proxyAddressTwoKeyRegistry;
    let proxyAddressTwoKeyEventSource;
    let proxyAddressTwoKeyExchange;
    let proxyAddressTwoKeyAdmin;
    let proxyAddressTwoKeyUpgradableExchange;
    let proxyAddressTwoKeyBaseReputationRegistry;
    let proxyAddressTwoKeyCommunityTokenPool;
    let proxyAddressTwoKeyLongTermTokenPool;
    let proxyAddressTwoKeyDeepFreezeTokenPool;
    let proxyAddressTwoKeyCampaignValidator;
    let proxyAddressTwoKeyFactory;
    let proxyAddressTwoKeyMaintainersRegistry;
    let proxyAddressTwoKeySignatureValidator;

    let proxyAddressTwoKeyUpgradableExchangeSTORAGE;
    let proxyAddressTwoKeyCampaignValidatorSTORAGE;
    let proxyAddressTwoKeyEventSourceSTORAGE;
    let proxyAddressTwoKeyAdminSTORAGE;
    let proxyAddressTwoKeyFactorySTORAGE;
    let proxyAddressTwoKeyMaintainersRegistrySTORAGE;
    let proxyAddressTwoKeyExchangeRateSTORAGE;
    let proxyAddressTwoKeyReputationRegistrySTORAGE;
    let proxyAddressTwoKeyCommunityTokenPoolSTORAGE;
    let proxyAddressTwoKeyDeepFreezeTokenPoolSTORAGE;
    let proxyAddressTwoKeyLongTermTokenPoolSTORAGE;
    let proxyAddressTwoKeyRegistrySTORAGE;
    let proxyAddressTwoKeySignatureValidatorSTORAGE;


    let deploymentNetwork;
    if(deployer.network.startsWith('dev') || deployer.network.startsWith('plasma-test')) {
        deploymentNetwork = 'dev-local-environment'
    } else if (deployer.network.startsWith('public') || deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deploymentNetwork = 'ropsten-environment';
    }

    /**
     * Initial voting powers for congress members
     * @type {number[]}
     */
    let maintainerAddresses = deploymentObject[deploymentNetwork].maintainers;
    let rewardsReleaseAfter = deploymentObject[deploymentNetwork].admin2keyReleaseDate; //1 January 2020


    let kyberAddress;
    /**
     * KYBER NETWORK ADDRESS and DAI ADDRESS
     */
    const KYBER_NETWORK_PROXY_ADDRESS_ROPSTEN = '0x818E6FECD516Ecc3849DAf6845e3EC868087B755';
    const DAI_ROPSTEN_ADDRESS = '0xaD6D458402F60fD3Bd25163575031ACDce07538D';
    const INITIAL_VERSION_OF_ALL_SINGLETONS = "1.0.0";

    console.log('Here');
    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {
            deployer.then(async () => {
                let registry = TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address);
                /**
                 * Here we will be adding all contracts to the Registry and create a Proxies for them
                 */
                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyRegistry to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyRegistry to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyRegistry", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyRegistry.address);
                        txHash = await registry.addVersion("TwoKeyRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyRegistryStorage.address);
                        let { logs } = await registry.createProxy("TwoKeyRegistry", "TwoKeyRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;

                        console.log('Proxy address for the TwoKeyRegistry is : ' + logicProxy);
                        console.log('Network ID', network_id);
                        const twoKeyReg = fileObject.TwoKeyRegistry || {};
                        twoKeyReg[network_id] = {
                            'implementationAddressLogic': TwoKeyRegistry.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyRegistryStorage.address,
                            'StorageProxy': storageProxy,
                        };


                        proxyAddressTwoKeyRegistrySTORAGE = storageProxy;
                        proxyAddressTwoKeyRegistry = logicProxy;
                        fileObject['TwoKeyRegistry'] = twoKeyReg;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

               await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeySignatureValidator to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeySignatureValidator to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeySignatureValidator", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeySignatureValidator.address);
                        txHash = await registry.addVersion("TwoKeySignatureValidatorStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeySignatureValidatorStorage.address);
                        let { logs } = await registry.createProxy("TwoKeySignatureValidator", "TwoKeySignatureValidatorStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;

                        console.log('Proxy address for the TwoKeySignatureValidator is : ' + logicProxy);
                        console.log('Network ID', network_id);
                        const twoKeySig = fileObject.TwoKeySignatureValidator || {};
                        twoKeySig[network_id] = {
                            'implementationAddressLogic': TwoKeySignatureValidator.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeySignatureValidatorStorage.address,
                            'StorageProxy': storageProxy,
                        };


                        proxyAddressTwoKeySignatureValidatorSTORAGE = storageProxy;
                        proxyAddressTwoKeySignatureValidator = logicProxy;
                        fileObject['TwoKeySignatureValidator'] = twoKeySig;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyMaintainersRegistry to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyMaintainersRegistry to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyMaintainersRegistry", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyMaintainersRegistry.address);
                        txHash = await registry.addVersion("TwoKeyMaintainersRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyMaintainersRegistryStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyMaintainersRegistry", "TwoKeyMaintainersRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy, storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyMaintainersRegistry is : ' + logicProxy);
                        const twoKeyMaintainersRegistry = fileObject.TwoKeyMaintainersRegistry || {};
                        twoKeyMaintainersRegistry[network_id] = {
                            'implementationAddressLogic': TwoKeyMaintainersRegistry.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyMaintainersRegistryStorage.address,
                            'StorageProxy': storageProxy,
                            'maintainers': maintainerAddresses
                        };
                        proxyAddressTwoKeyMaintainersRegistrySTORAGE = storageProxy;
                        proxyAddressTwoKeyMaintainersRegistry = logicProxy;

                        fileObject['TwoKeyMaintainersRegistry'] = twoKeyMaintainersRegistry;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyFactory to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyRegistry to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyFactory", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyFactory.address);
                        txHash = await registry.addVersion("TwoKeyFactoryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyFactoryStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyFactory", "TwoKeyFactoryStorage",INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;

                        console.log('Proxy address for the TwoKeyFactory is : ' + logicProxy);

                        const twoKeyFactory = fileObject.TwoKeyFactory || {};
                        twoKeyFactory[network_id] = {
                            'implementationAddressLogic': TwoKeyFactory.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyFactoryStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyFactorySTORAGE = storageProxy;
                        proxyAddressTwoKeyFactory = logicProxy;

                        fileObject['TwoKeyFactory'] = twoKeyFactory;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyCampaignValidator to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyCampaignValidator to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyCampaignValidator", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyCampaignValidator.address);
                        txHash = await registry.addVersion("TwoKeyCampaignValidatorStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyCampaignValidatorStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyCampaignValidator", "TwoKeyCampaignValidatorStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy , storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyCampaignValidator is : ' + logicProxy);
                        const twoKeyValidator = fileObject.TwoKeyCampaignValidator || {};
                        twoKeyValidator[network_id] = {
                            'implementationAddressLogic': TwoKeyCampaignValidator.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyCampaignValidatorStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyCampaignValidatorSTORAGE = storageProxy;

                        fileObject['TwoKeyCampaignValidator'] = twoKeyValidator;
                        proxyAddressTwoKeyCampaignValidator = logicProxy;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyCommunityTokenPool to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyCommunityTokenPool to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyCommunityTokenPool", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyCommunityTokenPool.address);
                        txHash = await registry.addVersion("TwoKeyCommunityTokenPoolStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyCommunityTokenPoolStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyCommunityTokenPool", "TwoKeyCommunityTokenPoolStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy , storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyCommunityTokenPool is : ' + logicProxy);
                        const twoKeyCommunityTokenPool = fileObject.TwoKeyCommunityTokenPool || {};

                        twoKeyCommunityTokenPool[network_id] = {
                            'implementationAddressLogic': TwoKeyCommunityTokenPool.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyCommunityTokenPoolStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyCommunityTokenPoolSTORAGE = storageProxy;
                        proxyAddressTwoKeyCommunityTokenPool = logicProxy;
                        fileObject['TwoKeyCommunityTokenPool'] = twoKeyCommunityTokenPool;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyLongTermTokenPool to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyLongTermTokenPool to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyLongTermTokenPool", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyLongTermTokenPool.address);
                        txHash =  await registry.addVersion("TwoKeyLongTermTokenPoolStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyLongTermTokenPoolStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyLongTermTokenPool", "TwoKeyLongTermTokenPoolStorage",INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyLongTermTokenPool is : ' + logicProxy);
                        const twoKeyLongTermTokenPool = fileObject.TwoKeyLongTermTokenPool || {};

                        twoKeyLongTermTokenPool[network_id] = {
                            'implementationAddressLogic': TwoKeyLongTermTokenPool.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyLongTermTokenPoolStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyLongTermTokenPoolSTORAGE = storageProxy;
                        proxyAddressTwoKeyLongTermTokenPool = logicProxy;

                        fileObject['TwoKeyLongTermTokenPool'] = twoKeyLongTermTokenPool;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyDeepFreezeTokenPool to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyLongTermTokenPool to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyDeepFreezeTokenPool", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyDeepFreezeTokenPool.address);
                        txHash = await registry.addVersion("TwoKeyDeepFreezeTokenPoolStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyDeepFreezeTokenPoolStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyDeepFreezeTokenPool","TwoKeyDeepFreezeTokenPoolStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyDeepFreezeTokenPool is : ' + logicProxy);

                        const twoKeyDeepFreezeTokenPool = fileObject.TwoKeyDeepFreezeTokenPool || {};
                        twoKeyDeepFreezeTokenPool[network_id] = {
                            'implementationAddressLogic': TwoKeyDeepFreezeTokenPool.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyDeepFreezeTokenPoolStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyDeepFreezeTokenPoolSTORAGE = storageProxy;
                        proxyAddressTwoKeyDeepFreezeTokenPool = logicProxy;

                        fileObject['TwoKeyDeepFreezeTokenPool'] = twoKeyDeepFreezeTokenPool;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });





                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyBaseReputationRegistry to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyBaseReputationRegistry to the registry, deploying 1st logicProxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyBaseReputationRegistry", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyBaseReputationRegistry.address);
                        txHash = await registry.addVersion("TwoKeyBaseReputationRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyBaseReputationRegistryStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyBaseReputationRegistry","TwoKeyBaseReputationRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyBaseReputationRegistry is : ' + logicProxy);
                        const twoKeyBaseRepReg = fileObject.TwoKeyBaseReputationRegistry || {};

                        twoKeyBaseRepReg[network_id] = {
                            'implementationAddressLogic': TwoKeyBaseReputationRegistry.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyBaseReputationRegistryStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyReputationRegistrySTORAGE = storageProxy;
                        proxyAddressTwoKeyBaseReputationRegistry = logicProxy;

                        fileObject['TwoKeyBaseReputationRegistry'] = twoKeyBaseRepReg;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('... Adding TwoKeyEventSource to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyEventSource to the registry, deploying 1st logicProxy for that 1.0 version of TwoKeyEventSource and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyEventSource", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyEventSource.address);
                        txHash = await registry.addVersion("TwoKeyEventSourceStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyEventSourceStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyEventSource", "TwoKeyEventSourceStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy , storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyEventSource is : ' + logicProxy);

                        const twoKeyEvents = fileObject.TwoKeyEventSource || {};

                        twoKeyEvents[network_id] = {
                            'implementationAddressLogic': TwoKeyEventSource.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyEventSourceStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyEventSourceSTORAGE = storageProxy;

                        fileObject['TwoKeyEventSource'] = twoKeyEvents;
                        proxyAddressTwoKeyEventSource = logicProxy;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyExchangeRateContract to Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyEventSource to the registry, deploying 1st logicProxy for that 1.0 version of TwoKeyEventSource
                         */
                        let txHash = await registry.addVersion("TwoKeyExchangeRateContract", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyExchangeRateContract.address);
                        txHash = await registry.addVersion("TwoKeyExchangeRateStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyExchangeRateStorage.address);
                        let { logs } = await registry.createProxy("TwoKeyExchangeRateContract", "TwoKeyExchangeRateStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy , storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyExchangeRateContract is : ' + logicProxy);

                        const twoKeyExchangeRate = fileObject.TwoKeyExchange || {};

                        twoKeyExchangeRate[network_id] = {
                            'implementationAddressLogic': TwoKeyExchangeRateContract.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyExchangeRateStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyExchangeRateSTORAGE = storageProxy;
                        proxyAddressTwoKeyExchange = logicProxy;
                        fileObject['TwoKeyExchangeRateContract'] = twoKeyExchangeRate;

                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyAdmin contract to logicProxy registry as valid implementation');
                        /**
                         * Adding TwoKeyAdmin to the registry, deploying 1st logicProxy for that 1.0 version of TwoKeyAdmin
                         */
                        let txHash = await registry.addVersion("TwoKeyAdmin", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyAdmin.address);
                        txHash = await registry.addVersion("TwoKeyAdminStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyAdminStorage.address);

                        let { logs } = await registry.createProxy("TwoKeyAdmin", "TwoKeyAdminStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy , storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyAdmin contract is : ' + logicProxy);


                        // txHash = await TwoKeyAdmin.at(logicProxy).transfer2KeyTokens(proxyAddressTwoKeyRegistry, 1000000000000000);
                        const twoKeyAdmin = fileObject.TwoKeyAdmin || {};
                        twoKeyAdmin[network_id] = {
                            'implementationAddressLogic': TwoKeyAdmin.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyAdminStorage.address,
                            'StorageProxy': storageProxy,
                        };


                        proxyAddressTwoKeyAdminSTORAGE = storageProxy;
                        proxyAddressTwoKeyAdmin = logicProxy;

                        fileObject['TwoKeyAdmin'] = twoKeyAdmin;

                        resolve(logicProxy);

                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyUpgradableExchange contract to logicProxy registry as valid implementation');
                        /**
                         * Adding TwoKeyUpgradableExchange to the registry, deploying 1st logicProxy for that 1.0 version of TwoKeyUpgradableExchange
                         */
                        let txHash = await registry.addVersion("TwoKeyUpgradableExchange", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyUpgradableExchange.address);
                        txHash = await registry.addVersion("TwoKeyUpgradableExchangeStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyUpgradableExchangeStorage.address);
                        let { logs } = await registry.createProxy("TwoKeyUpgradableExchange", "TwoKeyUpgradableExchangeStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);
                        let { logicProxy , storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        console.log('Proxy address for the TwoKeyUpgradableExchange contract is : ' + logicProxy);

                        const twoKeyUpgradableExchange = fileObject.TwoKeyUpgradableExchange || {};
                        twoKeyUpgradableExchange[network_id] = {
                            'implementationAddressLogic': TwoKeyUpgradableExchange.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyUpgradableExchangeStorage.address,
                            'StorageProxy': storageProxy,
                        };


                        proxyAddressTwoKeyUpgradableExchangeSTORAGE = storageProxy;
                        proxyAddressTwoKeyUpgradableExchange = logicProxy;

                        fileObject['TwoKeyUpgradableExchange'] = twoKeyUpgradableExchange;
                        fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .then(() => deployer.deploy(TwoKeyEconomy,proxyAddressTwoKeyAdmin, TwoKeySingletonesRegistry.address))
            .then(() => TwoKeyEconomy.deployed())
            .then(async () => {

                /**
                 * Here we will add congress contract to the registry
                 */
                await new Promise(async (resolve,reject) => {
                    try {

                        console.log('Adding non-upgradable contracts to the registry');
                        console.log('Adding TwoKeyCongress to the registry as non-upgradable contract');
                        let txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                            .addNonUpgradableContractToAddress('TwoKeyCongress', TwoKeyCongress.address);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                /**
                 * Here we will add economy contract to the registry
                 */
                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Adding TwoKeyEconomy to the registry as non-upgradable contract');
                        let txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                            .addNonUpgradableContractToAddress('TwoKeyEconomy', TwoKeyEconomy.address);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                /**
                 * Determine which network are we using
                 */
                if(deployer.network.startsWith('dev')) {
                    kyberAddress = KyberNetworkTestMockContract.address;
                } else {
                    kyberAddress = KYBER_NETWORK_PROXY_ADDRESS_ROPSTEN;
                }


                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyMaintainersRegistry');
                        let txHash = await TwoKeyMaintainersRegistry.at(proxyAddressTwoKeyMaintainersRegistry).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyMaintainersRegistrySTORAGE,
                            maintainerAddresses
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeySignatureValidator');
                        let txHash = await TwoKeySignatureValidator.at(proxyAddressTwoKeySignatureValidator).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeySignatureValidatorSTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyCommunityTokenPool');
                        let txHash = await TwoKeyCommunityTokenPool.at(proxyAddressTwoKeyCommunityTokenPool).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            TwoKeyEconomy.address,
                            proxyAddressTwoKeyCommunityTokenPoolSTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyLongTermTokenPool');
                        let txHash = await TwoKeyLongTermTokenPool.at(proxyAddressTwoKeyLongTermTokenPool).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            TwoKeyEconomy.address,
                            proxyAddressTwoKeyLongTermTokenPoolSTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyDeepFreezeTokenPool');
                        let txHash = await TwoKeyDeepFreezeTokenPool.at(proxyAddressTwoKeyDeepFreezeTokenPool).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            TwoKeyEconomy.address,
                            proxyAddressTwoKeyCommunityTokenPool,
                            proxyAddressTwoKeyDeepFreezeTokenPoolSTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyCampaignValidator');
                        let txHash = await TwoKeyCampaignValidator.at(proxyAddressTwoKeyCampaignValidator).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyCampaignValidatorSTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyEventSource');
                        let txHash = await TwoKeyEventSource.at(proxyAddressTwoKeyEventSource).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyEventSourceSTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyBaseReputationRegistry');
                        let txHash = await TwoKeyBaseReputationRegistry.at(proxyAddressTwoKeyBaseReputationRegistry).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyReputationRegistrySTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyExchangeRateContract');
                        let txHash = await TwoKeyExchangeRateContract.at(proxyAddressTwoKeyExchange).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyExchangeRateSTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyUpgradableExchange');
                        let txHash = await TwoKeyUpgradableExchange.at(proxyAddressTwoKeyUpgradableExchange).setInitialParams(
                            TwoKeyEconomy.address,
                            DAI_ROPSTEN_ADDRESS,
                            kyberAddress,
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyUpgradableExchangeSTORAGE
                        );

                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });


                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyAdmin');
                        let txHash = await TwoKeyAdmin.at(proxyAddressTwoKeyAdmin).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyAdminSTORAGE,
                            TwoKeyCongress.address,
                            TwoKeyEconomy.address,
                            deployer.network.startsWith('dev') ? 1 : rewardsReleaseAfter
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyFactory');
                        let txHash = await TwoKeyFactory.at(proxyAddressTwoKeyFactory).setInitialParams(
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyFactorySTORAGE
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Setting initial parameters in contract TwoKeyRegistry');
                        let txHash = await TwoKeyRegistry.at(proxyAddressTwoKeyRegistry).setInitialParams
                        (
                            TwoKeySingletonesRegistry.address,
                            proxyAddressTwoKeyRegistrySTORAGE
                        );

                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .then(() => true)
    } else if (deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        let proxyAddressTwoKeyPlasmaEvents;
        let proxyAddressTwoKeyPlasmaEventsSTORAGE;
        let proxyAddressTwoKeyPlasmaMaintainersRegistry;
        let proxyAddressTwoKeyPlasmaMaintainersRegistrySTORAGE;
        let proxyAddressTwoKeyPlasmaRegistry;
        let proxyAddressTwoKeyPlasmaRegistryStorage;

        const INITIAL_VERSION_OF_ALL_SINGLETONS = "1.0.0";

        deployer.link(Call, TwoKeyPlasmaEvents);
        deployer.link(Call, TwoKeyPlasmaRegistry);
        deployer.deploy(TwoKeyPlasmaEvents)
            .then(() => deployer.deploy(TwoKeyPlasmaMaintainersRegistry))
            .then(() => TwoKeyPlasmaMaintainersRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaRegistry))
            .then(() => TwoKeyPlasmaRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaSingletoneRegistry)) //adding empty admin address
            .then(() => TwoKeyPlasmaSingletoneRegistry.deployed().then(async (registry) => {
                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyPlasmaEvents to Plasma Proxy registry as valid implementation');

                        let txHash = await registry.addVersion("TwoKeyPlasmaEvents", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyPlasmaEvents.address);
                        txHash = await registry.addVersion("TwoKeyPlasmaEventsStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyPlasmaEventsStorage.address);
                        let { logs } = await registry.createProxy("TwoKeyPlasmaEvents", "TwoKeyPlasmaEventsStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);

                        let { logicProxy , storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        const twoKeyPlasmaEvents = fileObject.TwoKeyPlasmaEvents || {};
                        twoKeyPlasmaEvents[network_id] = {
                            'implementationAddressLogic': TwoKeyPlasmaEvents.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyPlasmaEventsStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyPlasmaEvents = logicProxy;
                        proxyAddressTwoKeyPlasmaEventsSTORAGE = storageProxy;
                        fileObject['TwoKeyPlasmaEvents'] = twoKeyPlasmaEvents;

                        resolve(proxyAddressTwoKeyPlasmaEventsSTORAGE);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyPlasmaRegistry to Plasma Proxy registry as valid implementation');

                        let txHash = await registry.addVersion("TwoKeyPlasmaRegistry", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyPlasmaRegistry.address);
                        txHash = await registry.addVersion("TwoKeyPlasmaRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyPlasmaRegistryStorage.address);
                        let { logs } = await registry.createProxy("TwoKeyPlasmaRegistry", "TwoKeyPlasmaRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);

                        let { logicProxy , storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        const twoKeyPlasmaEventsReg = fileObject.TwoKeyPlasmaEventsRegistry || {};
                        twoKeyPlasmaEventsReg[network_id] = {
                            'implementationAddressLogic': TwoKeyPlasmaRegistry.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyPlasmaRegistryStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyPlasmaRegistry = logicProxy;
                        proxyAddressTwoKeyPlasmaRegistryStorage = storageProxy;
                        fileObject['TwoKeyPlasmaRegistry'] = twoKeyPlasmaEventsReg;

                        resolve(proxyAddressTwoKeyPlasmaEventsSTORAGE);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyPlasmaMaintainersRegistry');
                        let txHash = await registry.addVersion("TwoKeyPlasmaMaintainersRegistry", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyPlasmaMaintainersRegistry.address);
                        txHash = await registry.addVersion("TwoKeyPlasmaMaintainersRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS, TwoKeyPlasmaMaintainersRegistryStorage.address);
                        let { logs } = await registry.createProxy("TwoKeyPlasmaMaintainersRegistry", "TwoKeyPlasmaMaintainersRegistryStorage", INITIAL_VERSION_OF_ALL_SINGLETONS);

                        let { logicProxy , storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;
                        const twoKeyPlasmaMaintainersRegistry = fileObject.TwoKeyPlasmaMaintainersRegistry || {};
                        twoKeyPlasmaMaintainersRegistry[network_id] = {
                            'implementationAddressLogic': TwoKeyPlasmaMaintainersRegistry.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyPlasmaMaintainersRegistryStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        proxyAddressTwoKeyPlasmaMaintainersRegistry = logicProxy;
                        proxyAddressTwoKeyPlasmaMaintainersRegistrySTORAGE = storageProxy;
                        fileObject['TwoKeyPlasmaMaintainersRegistry'] = twoKeyPlasmaMaintainersRegistry;

                        fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                        resolve(proxyAddressTwoKeyPlasmaMaintainersRegistrySTORAGE);
                    } catch (e) {
                        reject(e);
                    }
                })

            }))
            .then(async () => {
                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in plasma contract on plasma network');
                        let txHash = await TwoKeyPlasmaEvents.at(proxyAddressTwoKeyPlasmaEvents).setInitialParams
                        (
                            TwoKeyPlasmaSingletoneRegistry.address,
                            proxyAddressTwoKeyPlasmaEventsSTORAGE,
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in plasma registry contract on plasma network');
                        let txHash = await TwoKeyPlasmaRegistry.at(proxyAddressTwoKeyPlasmaRegistry).setInitialParams
                        (
                            TwoKeyPlasmaSingletoneRegistry.address,
                            proxyAddressTwoKeyPlasmaRegistryStorage
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });

                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in Maintainers contract on plasma network');
                        let txHash = await TwoKeyPlasmaMaintainersRegistry.at(proxyAddressTwoKeyPlasmaMaintainersRegistry).setInitialParams
                        (
                            TwoKeyPlasmaSingletoneRegistry.address,
                            proxyAddressTwoKeyPlasmaMaintainersRegistrySTORAGE,
                            maintainerAddresses
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .then(() => true)
            .catch((err) => {
                console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
            });
    }
};
