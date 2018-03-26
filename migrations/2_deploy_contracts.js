var TwoKeyAdmin = artifacts.require('TwoKeyAdmin')
var TwoKeyEconomy = artifacts.require('TwoKeyEconomy');

module.exports = function (deployer) {
  deployer.deploy(TwoKeyAdmin)
  deployer.deploy(TwoKeyEconomy)
}
