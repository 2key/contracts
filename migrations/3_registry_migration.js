const Registry = artifacts.require('TwoKeyReg');
const Campaign = artifacts.require('TwoKeyContract');

module.exports = function(deployer, network, accounts) {
  if (deployer.network == "development" || deployer.network == "rinkeby-infura") {
		deployer.deploy(Registry);
	}
};
