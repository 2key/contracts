// deploy the following contracts:
// * 2Key Economy, coinbase is the owner
// * 2Key registry
// * sample contract for each type of campagin.
// * Use fake constractor parameters. coinbase is the contractor
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
// const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');

module.exports = function (deployer) {
  if (deployer.network.startsWith('dev') || deployer.network == 'rinkeby-infura') {
    deployer.deploy(TwoKeyEconomy);
    // deployer.deploy(TwoKeyAdmin);
  } else if (deployer.network.startsWith('plasma')) {
    const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
    deployer.deploy(TwoKeyPlasmaEvents);
  }
};
