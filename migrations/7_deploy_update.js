const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const TwoKeyBaseReputationRegistry = artifacts.require('TwoKeyBaseReputationRegistry');
const TwoKeyCommunityTokenPool = artifacts.require('TwoKeyCommunityTokenPool');
const TwoKeyDeepFreezeTokenPool = artifacts.require('TwoKeyDeepFreezeTokenPool');
const TwoKeyLongTermTokenPool = artifacts.require('TwoKeyLongTermTokenPool');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyFactory = artifacts.require('TwoKeyFactory');
const TwoKeyMaintainersRegistry = artifacts.require('TwoKeyMaintainersRegistry');
const TwoKeySignatureValidator = artifacts.require('TwoKeySignatureValidator');
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaRegistry = artifacts.require('TwoKeyPlasmaRegistry');
const TwoKeyPlasmaMaintainersRegistry = artifacts.require('TwoKeyPlasmaMaintainersRegistry');

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
const TwoKeyPlasmaEventsStorage = artifacts.require('TwoKeyPlasmaEventsStorage');
const TwoKeyPlasmaMaintainersRegistryStorage = artifacts.require('TwoKeyPlasmaMaintainersRegistryStorage');
const TwoKeyPlasmaRegistryStorage = artifacts.require('TwoKeyPlasmaRegistryStorage');


const TWO_KEY_SINGLETON_REGISTRY_ADDRESS = "0x20a20172f22120f966530bb853e395f1682bb414"; //Develop
const TWO_KEY_PLASMA_SINGLETON_REGISTRY_ADDRESS = "0xc83b8a5c607b4d282c1d30a5a350e5529c007737"; //Staging

const { incrementVersion } = require('../helpers');


/**
 * Function to perform all necessary logic to update smart contract
 * @type {function(*, *=, *=)}
 */
const updateContract = (async (registryAddress, contractName, newImplementationAddress) => {
    await new Promise(async(resolve,reject) => {
        try {
            // Get current active version to be patched
            let version = await TwoKeySingletonesRegistry.at(registryAddress).getLatestContractVersion(contractName);
            // Incremented version
            let newVersion = incrementVersion(version);
            //Console log the new version
            console.log('New version is: ' + newVersion);
            // Add contract version
            let txHash = await TwoKeySingletonesRegistry.at(registryAddress).addVersion(contractName, newVersion, newImplementationAddress);
            // Upgrade contract proxy to new version
            let txHash1 = await TwoKeySingletonesRegistry.at(registryAddress).upgradeContract(contractName, newVersion);
            resolve({
                txHash, txHash1
            });
        } catch (e) {
            reject(e);
        }
    });
});

let contractsArtifacts = {
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
    TwoKeySignatureValidator,
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
    TwoKeySignatureValidatorStorage,
    TwoKeyPlasmaEvents,
    TwoKeyPlasmaMaintainersRegistry,
    TwoKeyPlasmaRegistry,
    TwoKeyPlasmaEventsStorage,
    TwoKeyPlasmaMaintainersRegistryStorage,
    TwoKeyPlasmaRegistryStorage
};



/**
 * Function to determine and return truffle build of selected contract
 * @type {function(*)}
 */
const getContractPerName = ((contractName) => {
    if(contractsArtifacts[contractName]) {
        return contractsArtifacts[contractName];
    }
    else return 'Wrong name';
});

/**
 * Validate arguments of method call
 * @type {function(*)}
 */
const checkArguments = ((arguments) => {
    let isArgumentFound = false;
    arguments.forEach((argument) => {
        if(argument == 'update') {
            isArgumentFound = true;
        }
    });

    return isArgumentFound;
});

module.exports = function deploy(deployer) {
    if(checkArguments(process.argv) == false) {
        console.log('No update will be performed');
        return;
    }

    let contractName = process.argv.pop();
    let contract = getContractPerName(contractName);
    let newImplementationAddress;
    let registryAddress;
    if(deployer.network.startsWith('dev')) {
        registryAddress = TwoKeySingletonesRegistry.address;
    }
    else if(deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {
        registryAddress = TWO_KEY_SINGLETON_REGISTRY_ADDRESS;
    } else {
        registryAddress = TWO_KEY_PLASMA_SINGLETON_REGISTRY_ADDRESS;
    }
    deployer.deploy(contract)
        .then(() => contract.deployed()
            .then(async (contractInstance) => {
                newImplementationAddress = contractInstance.address;
            })
            .then(async () => {
                console.log();
                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('Updating contract: ' + contractName);
                        let hashes = await updateContract(registryAddress, contractName, newImplementationAddress);
                        resolve(hashes);
                    } catch (e) {
                        reject(e);
                    }
                })
            })

        );
};
