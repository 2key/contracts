const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyWhitelistedInfluencer = artifacts.require('TwoKeyWhitelisted');
const TwoKeyWhitelistedConverter = artifacts.require('TwoKeyWhitelisted');
const TwoKeyCampaignInventory = artifacts.require('TwoKeyCampaignInventory');

module.exports = function deploy(deployer) {
    if (deployer.network.startsWith('dev') || deployer.network === 'rinkeby-infura') {
        deployer.deploy(TwoKeyWhitelistedInfluencer)
            .then(() => deployer.deploy(TwoKeyWhitelistedConverter))
            .then(() => deployer.deploy(TwoKeyAcquisitionCampaignERC20, EventSource.address, TwoKeyEconomy.address, TwoKeyWhitelistedInfluencer.address,
                TwoKeyWhitelistedConverter.address,'0xb3fa520368f2df7bed4df5185101f303f6c7decc',
                '0xb3fa520368f2df7bed4df5185101f303f6c7decc', 12345,12345,12345,12345,12345,12345, {gas: 20000000}))
            .then(() => true);
    }
};