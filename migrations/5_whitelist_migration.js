const Whitelist = artifacts.require('TwoKeyWhitelisted');

module.exports = function(deployer, network, accounts) {
  if (deployer.network.includes('dev')) {
		var whitelistInfluencer, whitelistConverter;
		deployer.deploy(Whitelist)
		.then(function(instance) {
			whitelistInfluencer = instance;
			return deployer.deploy(Whitelist);
		})
		.then(function(instance) {
			whitelistConverter = instance;
		});
  }
};
