const TwoKeyCampaignFactory = artifacts.require("TwoKeyCampaignFactory.sol");
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const EventSource = artifacts.require('TwoKeyEventSource');

module.exports = function deploy(deployer) {
    if (deployer.network.startsWith('dev') || deployer.network === 'rinkeby-infura') {
        deployer.deploy(TwoKeyCampaignFactory)
            .then(() => true);
    }
};