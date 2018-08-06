const EventSource = artifacts.require('TwoKeyEventSourceAlpha');

module.exports = function(deployer, network, accounts) {
  if (deployer.network.includes('dev') || deployer.network == "rinkeby-infura") {
    deployer.deploy(EventSource);
  }
};
