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
const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');


const fs = require('fs');
const path = require('path');

const deploymentConfigFile = path.join(__dirname, '../deploymentConfig.json');

module.exports = function deploy(deployer) {
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

    /**
     * Initial voting powers for congress members
     * @type {number[]}
     */
    let votingPowers = deploymentObject[deploymentNetwork].votingPowers;
    let initialCongressMembers = deploymentObject[deploymentNetwork].initialCongressMembers;
    let initialCongressMemberNames = deploymentObject[deploymentNetwork].initialCongressMembersNames;


    deployer.deploy(Call);
    deployer.deploy(IncentiveModels);
    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {
        deployer.deploy(TwoKeyCongress, 24 * 60, initialCongressMembers, initialCongressMemberNames, votingPowers)
            .then(() => TwoKeyCongress.deployed())
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
            .then(() => deployer.deploy(TwoKeyCommunityTokenPool))
            .then(() => TwoKeyCommunityTokenPool.deployed())
            .then(() => deployer.deploy(TwoKeyDeepFreezeTokenPool))
            .then(() => TwoKeyDeepFreezeTokenPool.deployed())
            .then(() => deployer.deploy(TwoKeyLongTermTokenPool))
            .then(() => TwoKeyLongTermTokenPool.deployed())
            .then(() => deployer.deploy(TwoKeyFactory))
            .then(() => TwoKeyFactory.deployed())
            .then(() => deployer.deploy(TwoKeyMaintainersRegistry))
            .then(() => TwoKeyMaintainersRegistry.deployed())
            .then(() => deployer.deploy(TwoKeySingletonesRegistry))
            .then(() => true);
    }
}
