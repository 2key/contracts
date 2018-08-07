const Registry = artifacts.require('TwoKeyReg');
const TwoKeySignedPresellContract = artifacts.require('TwoKeySignedPresellContract');

module.exports = function(deployer, network, accounts) {
  if (deployer.network.includes('dev') || deployer.network == "rinkeby-infura") {
		deployer.deploy(Registry);
	}
};
