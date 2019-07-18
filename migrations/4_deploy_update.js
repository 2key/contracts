const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
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


const TWO_KEY_SINGLETON_REGISTRY_ADDRESS = "0x20a20172f22120f966530bb853e395f1682bb414";
const TWO_KEY_PLASMA_SINGLETON_REGISTRY_ADDRESS = "0xe6ce6250dcfd0416325999f7891bbff668580a7a";

/**
 * Function to increment minor version
 * @type {function(*)}
 */
const incrementVersion = ((version) => {
    let vParts = version.split('.');
    // assign each substring a position within our array
    let partsArray = {
        major : vParts[0],
        minor : vParts[1],
        patch : vParts[2]
    };
    // target the substring we want to increment on
    partsArray.patch = parseFloat(partsArray.patch) + 1;
    // set an empty array to join our substring values back to
    let vArray = [];
    // grabs each property inside our partsArray object
    for (let prop in partsArray) {
        if (partsArray.hasOwnProperty(prop)) {
            // add each property to the end of our new array
            vArray.push(partsArray[prop]);
        }
    }
    // join everything back into one string with a period between each new property
    let newVersion = vArray.join('.');
    return newVersion;
});

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

/**
 * Function to downgrade contract version
 * @type {function(*, *=, *=)}
 */
const downgradeContract = (async (registryAddress, contractName, version) => {
    await new Promise(async(resolve,reject) => {
        try {
            let txHash = await TwoKeySingletonesRegistry.at(registryAddress).upgradeContract(contractName, version);
            resolve(txHash);
        } catch (e) {
            reject(e);
        }
    })
});


/**
 * Function to determine and return truffle build of selected contract
 * @type {function(*)}
 */
const getContractPerName = ((contractName) => {

    if(contractName == 'TwoKeyRegistry') {
        return TwoKeyRegistry;
    } else if (contractName == 'TwoKeyExchangeRateContract') {
        return TwoKeyExchangeRateContract;
    } else if (contractName == 'TwoKeyAdmin') {
        return TwoKeyAdmin;
    } else if (contractName == 'TwoKeyEventSource') {
        return EventSource;
    } else if (contractName == 'TwoKeyUpgradableExchange') {
        return TwoKeyUpgradableExchange;
    } else if (contractName == 'TwoKeyFactory') {
        return TwoKeyFactory;
    } else if (contractName == 'TwoKeyBaseReputationRegistry') {
        return TwoKeyBaseReputationRegistry;
    } else if (contractName == 'TwoKeyCampaignValidator') {
        return TwoKeyCampaignValidator;
    } else if (contractName == 'TwoKeyCommunityTokenPool') {
        return TwoKeyCommunityTokenPool;
    } else if (contractName == 'TwoKeyDeepFreezeTokenPool') {
        return TwoKeyDeepFreezeTokenPool;
    } else if (contractName == 'TwoKeyLongTermTokenPool') {
        return TwoKeyLongTermTokenPool;
    } else if (contractName == 'TwoKeyMaintainersRegistry') {
        return TwoKeyMaintainersRegistry;
    } else if (contractName == 'TwoKeyPlasmaEvents') {
        return TwoKeyPlasmaEvents;
    } else if (contractName == 'TwoKeyPlasmaMaintainersRegistry') {
        return TwoKeyPlasmaMaintainersRegistry;
    } else if (contractName == 'TwoKeyPlasmaRegistry') {
        return TwoKeyPlasmaRegistry;
    } else if (contractName == 'TwoKeySignatureValidator') {
        return TwoKeySignatureValidator;
    } else if(contractName == 'TwoKeyRegistryStorage') {
        return TwoKeyRegistryStorage;
    } else if (contractName == 'TwoKeyExchangeRateContractStorage') {
        return TwoKeyExchangeRateStorage;
    } else if (contractName == 'TwoKeyAdminStorage') {
        return TwoKeyAdminStorage;
    } else if (contractName == 'TwoKeyEventSourceStorage') {
        return TwoKeyEventSourceStorage;
    } else if (contractName == 'TwoKeyUpgradableExchangeStorage') {
        return TwoKeyUpgradableExchangeStorage;
    } else if (contractName == 'TwoKeyFactoryStorage') {
        return TwoKeyFactoryStorage;
    } else if (contractName == 'TwoKeyBaseReputationRegistryStorage') {
        return TwoKeyBaseReputationRegistryStorage;
    } else if (contractName == 'TwoKeyCampaignValidatorStorage') {
        return TwoKeyCampaignValidatorStorage;
    } else if (contractName == 'TwoKeyCommunityTokenPoolStorage') {
        return TwoKeyCommunityTokenPoolStorage;
    } else if (contractName == 'TwoKeyDeepFreezeTokenPoolStorage') {
        return TwoKeyDeepFreezeTokenPoolStorage;
    } else if (contractName == 'TwoKeyLongTermTokenPoolStorage') {
        return TwoKeyLongTermTokenPoolStorage;
    } else if (contractName == 'TwoKeyMaintainersRegistryStorage') {
        return TwoKeyMaintainersRegistryStorage;
    } else if (contractName == 'TwoKeyPlasmaEventsStorage') {
        return TwoKeyPlasmaEventsStorage;
    } else if (contractName == 'TwoKeyPlasmaMaintainersRegistryStorage') {
        return TwoKeyPlasmaMaintainersRegistryStorage;
    } else if (contractName == 'TwoKeyPlasmaRegistryStorage') {
        return TwoKeyPlasmaRegistryStorage;
    } else if (contractName == 'TwoKeySignatureValidatorStorage') {
        return TwoKeySignatureValidatorStorage;
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

    if(deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {
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
