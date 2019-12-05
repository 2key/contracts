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
const TwoKeyMPSNMiningPool = artifacts.require('TwoKeyMPSNMiningPool');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyFactory = artifacts.require('TwoKeyFactory');
const KyberNetworkTestMockContract = artifacts.require('KyberNetworkTestMockContract');
const TwoKeyMaintainersRegistry = artifacts.require('TwoKeyMaintainersRegistry');
const TwoKeySignatureValidator = artifacts.require('TwoKeySignatureValidator');
const TwoKeyParticipationPaymentsManager = artifacts.require('TwoKeyParticipationPaymentsManager');
const TwoKeyTeamGrowthFund = artifacts.require('TwoKeyTeamGrowthFund');

const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaRegistry = artifacts.require('TwoKeyPlasmaRegistry');
const TwoKeyPlasmaMaintainersRegistry = artifacts.require('TwoKeyPlasmaMaintainersRegistry');
const TwoKeyPlasmaCongress = artifacts.require('TwoKeyPlasmaCongress');
const TwoKeyPlasmaCongressMembersRegistry = artifacts.require('TwoKeyPlasmaCongressMembersRegistry');
const TwoKeyPlasmaFactory = artifacts.require('TwoKeyPlasmaFactory');

const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');
const MerkleProof = artifacts.require('MerkleProof');

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
    }
    else if (
        deployer.network.startsWith('public.test') ||
        deployer.network.startsWith('public.staging') ||
        deployer.network.startsWith('private.test') ||
        deployer.network.startsWith('private.staging'))
    {
        deploymentNetwork = 'ropsten-environment';
    }
    else if(deployer.network.startsWith('public.prod') ||deployer.network.startsWith('private.prod')) {
        deploymentNetwork = 'production'
    }

    return deploymentObject[deploymentNetwork];
});

let votingPowers;
let initialCongressMembers;
let initialCongressMemberNames;
let congressMinutesForDebate;

/**
 * Initial voting powers for congress members
 * @type {number[]}
 */

module.exports = function deploy(deployer) {
    let deploymentConfig = instantiateConfigs(deployer);

    congressMinutesForDebate = 24 * 60;

    deployer.deploy(Call);
    deployer.deploy(IncentiveModels);
    deployer.deploy(MerkleProof);

    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {


        votingPowers = deploymentConfig.votingPowers;
        initialCongressMembers = deploymentConfig.initialCongressMembers;
        initialCongressMemberNames = deploymentConfig.initialCongressMembersNames;


        deployer.deploy(TwoKeyCongress, congressMinutesForDebate)
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
            .then(() => deployer.deploy(TwoKeyMPSNMiningPool))
            .then(() => TwoKeyMPSNMiningPool.deployed())
            .then(() => deployer.deploy(TwoKeyTeamGrowthFund))
            .then(() => TwoKeyTeamGrowthFund.deployed())
            .then(() => deployer.deploy(TwoKeyFactory))
            .then(() => TwoKeyFactory.deployed())
            .then(() => deployer.deploy(TwoKeyMaintainersRegistry))
            .then(() => TwoKeyMaintainersRegistry.deployed())
            .then(() => deployer.deploy(TwoKeySingletonesRegistry))
            .then(() => true);
    }
    else if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {

        votingPowers = deploymentConfig.votingPowersPlasma;
        initialCongressMembers = deploymentConfig.initialCongressMembersPlasma;
        initialCongressMemberNames = deploymentConfig.initialCongressMembersNamesPlasma;


        deployer.link(Call, TwoKeyPlasmaEvents);
        deployer.link(Call, TwoKeyPlasmaRegistry);
        deployer.deploy(TwoKeyPlasmaCongress, congressMinutesForDebate)
            .then(() => TwoKeyPlasmaCongress.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaCongressMembersRegistry, initialCongressMembers, initialCongressMemberNames, votingPowers, TwoKeyPlasmaCongress.address))
            .then(() => TwoKeyPlasmaCongressMembersRegistry.deployed())
            .then(async () => {
                // Just to wire congress with congress members
                await new Promise(async(resolve,reject) => {
                    try {
                        let congress = await TwoKeyPlasmaCongress.at(TwoKeyPlasmaCongress.address);
                        let txHash = await congress.setTwoKeyCongressMembersContract(TwoKeyPlasmaCongressMembersRegistry.address);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })
            .then(() => deployer.deploy(TwoKeyPlasmaEvents))
            .then(() => TwoKeyPlasmaEvents.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaMaintainersRegistry))
            .then(() => TwoKeyPlasmaMaintainersRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaRegistry))
            .then(() => TwoKeyPlasmaRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaSingletoneRegistry)) //adding empty admin address
            .then(() => TwoKeyPlasmaSingletoneRegistry.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaFactory))
            .then(() => TwoKeyPlasmaFactory.deployed())
            .then(() => true);
    }
}
