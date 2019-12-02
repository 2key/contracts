const TwoKeyUpgradableExchangeStorage = artifacts.require('TwoKeyUpgradableExchangeStorage');
const TwoKeyCampaignValidatorStorage = artifacts.require('TwoKeyCampaignValidatorStorage');
const TwoKeyEventSourceStorage = artifacts.require("TwoKeyEventSourceStorage");
const TwoKeyAdminStorage = artifacts.require('TwoKeyAdminStorage');
const TwoKeyFactoryStorage = artifacts.require('TwoKeyFactoryStorage');
const TwoKeyMaintainersRegistryStorage = artifacts.require('TwoKeyMaintainersRegistryStorage');
const TwoKeyExchangeRateStorage = artifacts.require('TwoKeyExchangeRateStorage');
const TwoKeyBaseReputationRegistryStorage = artifacts.require('TwoKeyBaseReputationRegistryStorage');
const TwoKeyParticipationMiningPoolStorage = artifacts.require('TwoKeyParticipationMiningPoolStorage');
const TwoKeyParticipationPaymentsManagerStorage = artifacts.require('TwoKeyParticipationPaymentsManagerStorage');
const TwoKeyDeepFreezeTokenPoolStorage = artifacts.require('TwoKeyDeepFreezeTokenPoolStorage');
const TwoKeyNetworkGrowthFundStorage = artifacts.require('TwoKeyNetworkGrowthFundStorage');
const TwoKeyRegistryStorage = artifacts.require('TwoKeyRegistryStorage');
const TwoKeySignatureValidatorStorage = artifacts.require('TwoKeySignatureValidatorStorage');
const TwoKeyMPSNMiningPoolStorage = artifacts.require('TwoKeyMPSNMiningPoolStorage');
const TwoKeyTeamGrowthFundStorage = artifacts.require('TwoKeyTeamGrowthFundStorage');
const TwoKeyPlasmaEventsStorage = artifacts.require('TwoKeyPlasmaEventsStorage');
const TwoKeyPlasmaMaintainersRegistryStorage = artifacts.require('TwoKeyPlasmaMaintainersRegistryStorage');
const TwoKeyPlasmaRegistryStorage = artifacts.require('TwoKeyPlasmaRegistryStorage');
const TwoKeyPlasmaFactoryStorage = artifacts.require('TwoKeyPlasmaFactoryStorage');


module.exports = function deploy(deployer) {
    if(deployer.network.startsWith('public') || deployer.network.startsWith('dev')) {
        deployer.deploy(TwoKeyCampaignValidatorStorage)
            .then(() =>TwoKeyCampaignValidatorStorage.deployed())
            .then(() => deployer.deploy(TwoKeyUpgradableExchangeStorage))
            .then(() => TwoKeyUpgradableExchangeStorage.deployed())
            .then(() => deployer.deploy(TwoKeyEventSourceStorage))
            .then(() => TwoKeyEventSourceStorage.deployed())
            .then(() => deployer.deploy(TwoKeyAdminStorage))
            .then(() => TwoKeyAdminStorage.deployed())
            .then(() => deployer.deploy(TwoKeyFactoryStorage))
            .then(() => TwoKeyFactoryStorage.deployed())
            .then(() => deployer.deploy(TwoKeyMaintainersRegistryStorage))
            .then(() => TwoKeyMaintainersRegistryStorage.deployed())
            .then(() => deployer.deploy(TwoKeyExchangeRateStorage))
            .then(() => TwoKeyExchangeRateStorage.deployed())
            .then(() => deployer.deploy(TwoKeyBaseReputationRegistryStorage))
            .then(() => TwoKeyBaseReputationRegistryStorage.deployed())
            .then(() => deployer.deploy(TwoKeyParticipationMiningPoolStorage))
            .then(() => TwoKeyParticipationMiningPoolStorage.deployed())
            .then(() => deployer.deploy(TwoKeyParticipationPaymentsManagerStorage))
            .then(() => TwoKeyParticipationPaymentsManagerStorage.deployed())
            .then(() => deployer.deploy(TwoKeyDeepFreezeTokenPoolStorage))
            .then(() => TwoKeyDeepFreezeTokenPoolStorage.deployed())
            .then(() => deployer.deploy(TwoKeyMPSNMiningPoolStorage))
            .then(() => TwoKeyMPSNMiningPoolStorage.deployed())
            .then(() => deployer.deploy(TwoKeyNetworkGrowthFundStorage))
            .then(() => TwoKeyNetworkGrowthFundStorage.deployed())
            .then(() => deployer.deploy(TwoKeyTeamGrowthFundStorage))
            .then(() => TwoKeyTeamGrowthFundStorage.deployed())
            .then(() => deployer.deploy(TwoKeyRegistryStorage))
            .then(() => TwoKeyRegistryStorage.deployed())
            .then(() => deployer.deploy(TwoKeySignatureValidatorStorage))
            .then(() => TwoKeySignatureValidatorStorage.deployed())
            .then(() => true);
    } else if (deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.deploy(TwoKeyPlasmaEventsStorage)
            .then(() => TwoKeyPlasmaEventsStorage.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaMaintainersRegistryStorage))
            .then(() => TwoKeyPlasmaMaintainersRegistryStorage.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaRegistryStorage))
            .then(() => TwoKeyPlasmaRegistryStorage.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaFactoryStorage))
            .then(() => TwoKeyPlasmaFactoryStorage.deployed())
            .then(() => true);
    } else {
        console.log('No deployment configuration for selected network');
    }

};
