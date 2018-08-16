const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');

module.exports = function(deployer, network, accounts) {
  if (deployer.network.includes('dev') || deployer.network == "rinkeby-infura") {
    // deployer.deploy(TwoKeyAdmin)
    //     .then(() => deployer.deploy(EventSource, TwoKeyAdmin.address))
    //     .then(() => true);

      deployer.deploy(EventSource, "0x0");
  }
};




