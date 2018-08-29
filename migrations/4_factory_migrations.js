const TwoKeyCampaignFactory = artifacts.require("TwoKeyCampaignFactory.sol");
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const EventSource = artifacts.require('TwoKeyEventSource');

module.exports = function deploy(deployer) {
    if (deployer.network.startsWith('dev') || deployer.network === 'rinkeby-infura') {

        /*
            Opening and closing time for ComposableAssetFactory constructor
         */

        let openingTime =  new Date().getTime() + 2000;
        let closingTime = new Date().getTime() + 10000;

        deployer.deploy(TwoKeyCampaignFactory, openingTime, closingTime)
            .then(() => true);
    }
};