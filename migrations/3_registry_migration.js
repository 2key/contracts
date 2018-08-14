const Registry = artifacts.require('TwoKeyReg');
const TwoKeyCampaignETH = artifacts.require('TwoKeyCampaignETH');

module.exports = function(deployer, network, accounts) {
  if (deployer.network.includes('dev') || deployer.network == "rinkeby-infura") {
		deployer.deploy(Registry);
	}
};
