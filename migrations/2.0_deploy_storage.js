const TwoKeyUpgradableExchangeStorage = artifacts.require('TwoKeyUpgradableExchangeStorage');
const TwoKeyCampaignValidatorStorage = artifacts.require('TwoKeyCampaignValidatorStorage');
const TwoKeyEventSourceStorage = artifacts.require("TwoKeyEventSourceStorage");


module.exports = function deploy(deployer) {
    deployer.deploy(TwoKeyCampaignValidatorStorage)
    .then(() => TwoKeyCampaignValidatorStorage.deployed())
    .then(() => deployer.deploy(TwoKeyUpgradableExchangeStorage))
    .then(() => TwoKeyUpgradableExchangeStorage.deployed())
    .then(() => deployer.deploy(TwoKeyEventSourceStorage))
    .then(() => TwoKeyEventSourceStorage.deployed())
    .then(() => true);
};
