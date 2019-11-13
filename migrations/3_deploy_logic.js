const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const TwoKeyCongressMembersRegistry = artifacts.require('TwoKeyCongressMembersRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
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
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaRegistry = artifacts.require('TwoKeyPlasmaRegistry');
const TwoKeyPlasmaMaintainersRegistry = artifacts.require('TwoKeyPlasmaMaintainersRegistry');

const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');


const fs = require('fs');
const path = require('path');

const deploymentConfigFile = path.join(__dirname, '../configurationFiles/deploymentConfig.json');

const instantiateConfigs = ((deployer) => {
    let deploymentObject = {};
    if (fs.existsSync(deploymentConfigFile)) {
        deploymentObject = JSON.parse(fs.readFileSync(deploymentConfigFile, {encoding: 'utf8'}));
    }

    let deploymentNetwork;
    if (deployer.network.startsWith('dev') || deployer.network.startsWith('plasma-test')) {
        deploymentNetwork = 'dev-local-environment'
    } else if (deployer.network.startsWith('public') || deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deploymentNetwork = 'ropsten-environment';
    }

    return deploymentObject[deploymentNetwork];

});

module.exports = function deploy(deployer) {


    let deploymentConfig = instantiateConfigs(deployer);

    /**
     * Initial voting powers for congress members
     * @type {number[]}
     */
    let votingPowers = deploymentConfig.votingPowers;
    let initialCongressMembers = deploymentConfig.initialCongressMembers;
    let initialCongressMemberNames = deploymentConfig.initialCongressMembersNames;


    deployer.deploy(Call);
    deployer.deploy(IncentiveModels);

    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {
        deployer.deploy(TwoKeyCongress, 24 * 60)
            .then(() => TwoKeyCongress.deployed())
            .then(() => deployer.deploy(TwoKeyCongressMembersRegistry, initialCongressMembers, initialCongressMemberNames, votingPowers, TwoKeyCongress.address))
            .then(() => TwoKeyCongressMembersRegistry.deployed())
            .then(async () => {
                // Just to wire congress with congress members
                await new Promise(async(resolve,reject) => {
                    try {
                        let congress = await TwoKeyCongress.at(TwoKeyCongress.address);
                        let txHash = await congress.setTwoKeyCongressMembersContract(TwoKeyCongressMembersRegistry.address);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })
            .then(() => deployer.deploy(TwoKeyCampaignValidator))
            .then(() => deployer.link(Call, TwoKeySignatureValidator))
            .then(() => deployer.deploy(TwoKeySignatureValidator))
            .then(() => TwoKeySignatureValidator.deployed())
            .then(() => TwoKeyCampaignValidator.deployed())
            .then(() => deployer.deploy(TwoKeyAdmin))
            .then(() => TwoKeyAdmin.deployed())
            .then(() => deployer.deploy(TwoKeyExchangeRateContract))
            .then(() => TwoKeyExchangeRateContract.deployed())
            .then(() => deployer.deploy(TwoKeyEventSource))
            .then(() => deployer.link(Call, TwoKeyRegistry))
            .then(() => deployer.deploy(TwoKeyRegistry))
            .then(() => TwoKeyRegistry.deployed())
            .then(() => deployer.deploy(KyberNetworkTestMockContract))
            .then(() => KyberNetworkTestMockContract.deployed())
            .then(() => deployer.deploy(TwoKeyBaseReputationRegistry))
            .then(() => TwoKeyBaseReputationRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyUpgradableExchange))
            .then(() => TwoKeyUpgradableExchange.deployed())
            .then(() => deployer.deploy(TwoKeyParticipationMiningPool))
            .then(() => TwoKeyParticipationMiningPool.deployed())
            .then(() => deployer.deploy(TwoKeyParticipationPaymentsManager))
            .then(() => TwoKeyParticipationPaymentsManager.deployed())
            .then(() => deployer.deploy(TwoKeyDeepFreezeTokenPool))
            .then(() => TwoKeyDeepFreezeTokenPool.deployed())
            .then(() => deployer.deploy(TwoKeyNetworkGrowthFund))
            .then(() => TwoKeyNetworkGrowthFund.deployed())
            .then(() => deployer.deploy(TwoKeyFactory))
            .then(() => TwoKeyFactory.deployed())
            .then(() => deployer.deploy(TwoKeyMaintainersRegistry))
            .then(() => TwoKeyMaintainersRegistry.deployed())
            .then(() => deployer.deploy(TwoKeySingletonesRegistry))
            .then(() => true);
    }
    else if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.link(Call, TwoKeyPlasmaEvents);
        deployer.link(Call, TwoKeyPlasmaRegistry);
        deployer.deploy(TwoKeyPlasmaEvents)
            .then(() => deployer.deploy(TwoKeyPlasmaMaintainersRegistry))
            .then(() => TwoKeyPlasmaMaintainersRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaRegistry))
            .then(() => TwoKeyPlasmaRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaSingletoneRegistry)) //adding empty admin address
            .then(() => TwoKeyPlasmaSingletoneRegistry.deployed())
    }
}
