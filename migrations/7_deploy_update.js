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
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const StandardTokenModified = artifacts.require('StandardTokenModified');
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
const Call = artifacts.require('Call');

const { incrementVersion, getConfigForTheBranch, slack_message_proposal_created, checkArgumentsForUpdate } = require('../helpers');
const { generateBytecodeForUpgrading } = require('../generateBytecode');

/**
 * Function to perform all necessary logic to update smart contract
 * @type {function(*, *=, *=)}
 */
const updateContract = (async (registryAddress, congressAddress, contractName, newImplementationAddress, network) => {
    await new Promise(async(resolve,reject) => {
        try {
            let instance = await TwoKeySingletonesRegistry.at(registryAddress);
            // Get current active version to be patched
            let version = await instance.getLatestContractVersion(contractName);
            // Incremented version
            let newVersion = incrementVersion(version);
            //Console log the new version
            console.log('New version is: ' + newVersion);
            // Add contract version. This can be done only by core dev
            let txHash = await instance.addVersion(contractName, newVersion, newImplementationAddress);
            //Generate bytecode
            let bytecodeForUpgradingThisContract = generateBytecodeForUpgrading(contractName, newVersion);

            // await slack_message_proposal_created(contractName, newVersion, bytecodeForUpgradingThisContract, network);

            resolve({
                txHash //, txHash1
            });
        } catch (e) {
            reject(e);
        }
    });
});

/**
 * Upgrade contract on plasma network
 * @type {function(*=, *=, *=)}
 */
const updateContractPlasma = (async (registryAddress, contractName, newImplementationAddress) => {
    await new Promise(async(resolve,reject) => {
        try {
            let instance = await TwoKeyPlasmaSingletoneRegistry.at(registryAddress);
            // Get current active version to be patched
            let version = await instance.getLatestContractVersion(contractName);
            // Incremented version
            let newVersion = incrementVersion(version);
            //Console log the new version
            console.log('New version is: ' + newVersion);
            // Add contract version. This can be done only by deployer
            let txHash = await instance.addVersion(contractName, newVersion, newImplementationAddress);
            // Upgrade contract --> can be only done by deployer
            let txHash1 = await instance.upgradeContract(contractName, newVersion);
            resolve({
                txHash , txHash1
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
    TwoKeyPlasmaRegistryStorage,
    TwoKeyPlasmaSingletoneRegistry
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


module.exports = async function deploy(deployer) {

    let flag = false;
    process.argv.forEach((argument) => {
        if(argument === 'update') {
            flag = true;
        }
    });

    if(flag == false) {
        console.log('No update will be performed');
        return;
    }

    let contractName = process.argv.pop();
    let contract = getContractPerName(contractName);
    let newImplementationAddress;
    let registryAddress;
    let congressAddress;


    deployer.deploy(contract)
        .then(() => contract.deployed()
            .then(async (contractInstance) => {
                newImplementationAddress = contractInstance.address;
            })
            .then(async () => {
                let config = await getConfigForTheBranch();

                if(deployer.network.startsWith('dev')) {
                    registryAddress = TwoKeySingletonesRegistry.address;
                    congressAddress = TwoKeyCongress.address;
                }
                else if(deployer.network.startsWith('private') || deployer.network.startsWith('plasma')) {
                    registryAddress = config.TwoKeyPlasmaSingletoneRegistry.networks[deployer.network_id].address;
                }
                else if(deployer.network.startsWith('public')) {
                    registryAddress = config.TwoKeySingletonesRegistry.networks[deployer.network_id].address;
                    congressAddress = config.TwoKeyCongress.networks[deployer.network_id].address;
                }

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('Updating contract: ' + contractName);
                        if(deployer.network.startsWith('private')) {
                            let {txHash, txHash1} = updateContractPlasma(registryAddress, contractName, newImplementationAddress);
                        } else if (deployer.network.startsWith('public')){
                            let txHash = await updateContract(registryAddres, congressAddress, contractName, newImplementationAddress, deployer.network);
                        }
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })
        )
        .then(() => true);
};
