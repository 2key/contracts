const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const TwoKeyBaseReputationRegistry = artifacts.require('TwoKeyBaseReputationRegistry');
const TwoKeyDeepFreezeTokenPool = artifacts.require('TwoKeyDeepFreezeTokenPool');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyFactory = artifacts.require('TwoKeyFactory');
const TwoKeyMaintainersRegistry = artifacts.require('TwoKeyMaintainersRegistry');
const TwoKeySignatureValidator = artifacts.require('TwoKeySignatureValidator');
const TwoKeyParticipationPaymentsManager = artifacts.require('TwoKeyParticipationPaymentsManager');
const TwoKeyFeeManager = artifacts.require('TwoKeyFeeManager');
const TwoKeyNetworkGrowthFund = artifacts.require('TwoKeyNetworkGrowthFund');
const TwoKeyParticipationMiningPool = artifacts.require('TwoKeyParticipationMiningPool');
const TwoKeyPlasmaBudgetCampaignsPaymentsHandler = artifacts.require('TwoKeyPlasmaBudgetCampaignsPaymentsHandler');
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaRegistry = artifacts.require('TwoKeyPlasmaRegistry');
const TwoKeyPlasmaMaintainersRegistry = artifacts.require('TwoKeyPlasmaMaintainersRegistry');
const TwoKeyPlasmaFactory = artifacts.require('TwoKeyPlasmaFactory');
const TwoKeyPlasmaEventSource = artifacts.require('TwoKeyPlasmaEventSource');
const TwoKeyPlasmaParticipationRewards = artifacts.require('TwoKeyPlasmaParticipationRewards');

const TwoKeyUpgradableExchangeStorage = artifacts.require('TwoKeyUpgradableExchangeStorage');
const TwoKeyCampaignValidatorStorage = artifacts.require('TwoKeyCampaignValidatorStorage');
const TwoKeyEventSourceStorage = artifacts.require("TwoKeyEventSourceStorage");
const TwoKeyAdminStorage = artifacts.require('TwoKeyAdminStorage');
const TwoKeyFactoryStorage = artifacts.require('TwoKeyFactoryStorage');
const TwoKeyMaintainersRegistryStorage = artifacts.require('TwoKeyMaintainersRegistryStorage');
const TwoKeyExchangeRateStorage = artifacts.require('TwoKeyExchangeRateStorage');
const TwoKeyBaseReputationRegistryStorage = artifacts.require('TwoKeyBaseReputationRegistryStorage');
const TwoKeyDeepFreezeTokenPoolStorage = artifacts.require('TwoKeyDeepFreezeTokenPoolStorage');
const TwoKeyRegistryStorage = artifacts.require('TwoKeyRegistryStorage');
const TwoKeySignatureValidatorStorage = artifacts.require('TwoKeySignatureValidatorStorage');
const TwoKeyParticipationPaymentsManagerStorage = artifacts.require('TwoKeyParticipationPaymentsManagerStorage');
const TwoKeyFeeManagerStorage = artifacts.require('TwoKeyFeeManagerStorage');
const TwoKeyNetworkGrowthFundStorage = artifacts.require('TwoKeyNetworkGrowthFundStorage');
const TwoKeyBudgetCampaignsPaymentsHandler = artifacts.require('TwoKeyBudgetCampaignsPaymentsHandler');
const TwoKeyPlasmaEventsStorage = artifacts.require('TwoKeyPlasmaEventsStorage');
const TwoKeyPlasmaMaintainersRegistryStorage = artifacts.require('TwoKeyPlasmaMaintainersRegistryStorage');
const TwoKeyPlasmaRegistryStorage = artifacts.require('TwoKeyPlasmaRegistryStorage');
const TwoKeyPlasmaEventSourceStorage = artifacts.require('TwoKeyPlasmaEventSourceStorage');
const TwoKeyPlasmaReputationRegistry = artifacts.require('TwoKeyPlasmaReputationRegistry');
const Call = artifacts.require('Call');
const PriceDiscovery = artifacts.require('PriceDiscovery');

const { incrementVersion, getConfigForTheBranch, slack_message_proposal_created, } = require('../helpers');
const { generateBytecodeForUpgrading } = require('../generateBytecode');

const fs = require('fs');
const path = require('path');
const proxyFile = path.join(__dirname, '../build/proxyAddresses.json');


/**
 * Function to perform all necessary logic to update smart contract
 * @type {function(*, *=, *=)}
 */
const updateContract = (async (registryAddress, contractName, newImplementationAddress, deployer) => {
    await new Promise(async(resolve,reject) => {
        try {

            //Open proxyAddresses file
            let fileObject = {};
            if (fs.existsSync(proxyFile)) {
                fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
            }
            console.log('Deployer network ID : ' + deployer.network_id.toString());
            //Override logic address implementation
            fileObject[contractName][deployer.network_id.toString()].implementationAddressLogic = newImplementationAddress;

            //Write new logic address to proxyAddresses file
            fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
            //Get instance of TwoKeySingletonesRegistry
            let instance = await TwoKeySingletonesRegistry.at(registryAddress);
            // Get current active version to be patched
            let version = await instance.getLatestAddedContractVersion(contractName);
            // Incremented version
            let newVersion = incrementVersion(version);
            //Console log the new version
            console.log('New version is: ' + newVersion);
            // Add contract version. This can be done only by core dev
            let txHash = await instance.addVersion(contractName, newVersion, newImplementationAddress);
            //Generate bytecode
            let bytecodeForUpgradingThisContract = generateBytecodeForUpgrading(contractName, newVersion);
            //Message on slack that proposal should be created for new version
            await slack_message_proposal_created(contractName, newVersion, bytecodeForUpgradingThisContract, deployer.network);

            resolve({
                txHash
            });
        } catch (e) {
            reject(e);
        }
    });
});



let contractsArtifacts = {
    TwoKeyPlasmaBudgetCampaignsPaymentsHandler,
    TwoKeyUpgradableExchange,
    TwoKeyAdmin,
    TwoKeyEventSource,
    TwoKeyRegistry,
    TwoKeyExchangeRateContract,
    TwoKeyBaseReputationRegistry,
    TwoKeyDeepFreezeTokenPool,
    TwoKeyCampaignValidator,
    TwoKeyFactory,
    TwoKeyMaintainersRegistry,
    TwoKeySignatureValidator,
    TwoKeyParticipationPaymentsManager,
    TwoKeyFeeManager,
    TwoKeyNetworkGrowthFund,
    TwoKeyParticipationMiningPool,
    TwoKeyUpgradableExchangeStorage,
    TwoKeyAdminStorage,
    TwoKeyEventSourceStorage,
    TwoKeyRegistryStorage,
    TwoKeyExchangeRateStorage,
    TwoKeyBaseReputationRegistryStorage,
    TwoKeyDeepFreezeTokenPoolStorage,
    TwoKeyCampaignValidatorStorage,
    TwoKeyFactoryStorage,
    TwoKeyMaintainersRegistryStorage,
    TwoKeySignatureValidatorStorage,
    TwoKeyParticipationPaymentsManagerStorage,
    TwoKeyFeeManagerStorage,
    TwoKeyNetworkGrowthFundStorage,
    TwoKeyBudgetCampaignsPaymentsHandler,
    TwoKeyPlasmaEvents,
    TwoKeyPlasmaMaintainersRegistry,
    TwoKeyPlasmaRegistry,
    TwoKeyPlasmaEventsStorage,
    TwoKeyPlasmaMaintainersRegistryStorage,
    TwoKeyPlasmaRegistryStorage,
    TwoKeyPlasmaSingletoneRegistry,
    TwoKeyPlasmaFactory,
    TwoKeyPlasmaEventSource,
    TwoKeyPlasmaReputationRegistry,
    TwoKeyPlasmaParticipationRewards
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


    console.log('Contract updating: ',contractName);

    if(contractName === 'TwoKeyParticipationMiningPool') {
        deployer.link(Call, contract);
    }
    deployer.deploy(contract)
        .then(() => contract.deployed()
            .then(async (contractInstance) => {
                console.log('Deployed to selected network');
                newImplementationAddress = contractInstance.address;
            })
            .then(async () => {
                console.log('Finding configuration files addresses for desired network');

                let config = await getConfigForTheBranch();

                if(deployer.network.startsWith('dev')) {
                    registryAddress = TwoKeySingletonesRegistry.address;
                }
                else if(deployer.network.startsWith('private') || deployer.network.startsWith('plasma')) {
                    registryAddress = config.TwoKeyPlasmaSingletoneRegistry.networks[deployer.network_id].address;
                }
                else if(deployer.network.startsWith('public')) {
                    registryAddress = config.TwoKeySingletonesRegistry.networks[deployer.network_id].address;
                }

                await new Promise(async (resolve, reject) => {
                    try {
                        console.log('Updating contract: ' + contractName);
                        let txHash = await updateContract(registryAddress, contractName, newImplementationAddress, deployer);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })
        )
        .then(() => true);
};
