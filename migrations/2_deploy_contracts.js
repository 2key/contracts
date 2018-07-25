// deploy the following contracts:
// * 2Key Economy, coinbase is the owner
// * 2Key registry
// * sample contract for each type of campagin. Use fake constractor parameters. coinbase is the contractor
var TwoKeyEconomy = artifacts.require('TwoKeyEconomy');

module.exports = function (deployer) {
  if (deployer.network == "development" || deployer.network == "rinkeby-infura" || deployer.network == "test-prv") {
    deployer.deploy(TwoKeyEconomy)
  } else if (deployer.network == "plasma") {
    var TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents')
    deployer.deploy(TwoKeyPlasmaEvents)
  }
}
