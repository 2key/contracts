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
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaEventsRegistry = artifacts.require('TwoKeyPlasmaEventsRegistry');
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
const TwoKeyPlasmaEventsStorage = artifacts.require('TwoKeyPlasmaEventsStorage');
const TwoKeyPlasmaMaintainersRegistryStorage = artifacts.require('TwoKeyPlasmaMaintainersRegistryStorage');
const TwoKeyPlasmaEventsRegistryStorage = artifacts.require('TwoKeyPlasmaEventsRegistryStorage');

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
    }
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
const updateContract = (async (registry, contractName, newImplementationAddress) => {
    await new Promise(async(resolve,reject) => {
        try {
            // Get current active version to be patched
            let version = await registry.getLatestContractVersion(contractName);
            // Incremented version
            let newVersion = incrementVersion(version);
            //Console log the new version
            console.log('New version is: ' + newVersion);
            // Add contract version
            let txHash = await registry.addVersion(contractName, newVersion, newImplementationAddress);
            // Upgrade contract proxy to new version
            let txHash1 = await registry.upgradeContract(contractName, newVersion);
            resolve({
                txHash, txHash1
            });
        } catch (e) {
            reject(e);
        }
    });
});

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
    } else if (contractName == 'TwoKeyPlasmaEventsRegistry') {
        return TwoKeyPlasmaEventsRegistry;
    } else return 'Wrong name';
});

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

    deployer.deploy(contract)
        .then(() => contract.deployed()
            .then(async (contractInstance) => {
                newImplementationAddress = contractInstance.address;
            })
            .then(() => TwoKeySingletonesRegistry.deployed()
                .then(async (registry) => {
                        await new Promise(async (resolve, reject) => {
                            try {
                                console.log('Updating contract: ' + contractName);
                                let hashes = await updateContract(registry, contractName, newImplementationAddress);
                                resolve(hashes);
                            } catch (e) {
                                reject(e);
                            }
                        })
                    }
                )
            )
        );

};
