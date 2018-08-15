const EventSource = artifacts.require('TwoKeyEventSource');

module.exports = function(deployer, network, accounts) {
  if (deployer.network.startsWith('dev') || deployer.network == "rinkeby-infura") {
    deployer.deploy(EventSource);
  }
};
