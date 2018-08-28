/* global artifacts */
const Migrations = artifacts.require('./Migrations.sol');

module.exports = function deploy(deployer) {
  deployer.deploy(Migrations);
};
