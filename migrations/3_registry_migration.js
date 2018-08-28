/* global artifacts */
const Registry = artifacts.require('TwoKeyReg');

module.exports = function deploy(deployer, network, accounts) {
  if (deployer.network.startsWith('dev') || deployer.network === 'rinkeby-infura') {
    deployer.deploy(Registry);
  }
};
