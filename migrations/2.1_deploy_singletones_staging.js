const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyReg = artifacts.require('TwoKeyReg');

module.exports = function deploy(deployer) {
  if (deployer.network === 'staging') {
    deployer.deploy(ERC20TokenMock)
      .then(() => ERC20TokenMock.deployed())
      .then(() => deployer.deploy(TwoKeyAdmin, '0xb3fa520368f2df7bed4df5185101f303f6c7decc'))
      .then(() => TwoKeyAdmin.deployed())
      .then(() => deployer.deploy(TwoKeyUpgradableExchange, 1, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', ERC20TokenMock.address,TwoKeyAdmin.address))
      .then(() => TwoKeyUpgradableExchange.deployed())
      .then(() => deployer.deploy(TwoKeyEconomy, TwoKeyAdmin.address))
      .then(() => deployer.deploy(EventSource, TwoKeyAdmin.address))
      .then(() => deployer.deploy(TwoKeyReg, EventSource.address, TwoKeyAdmin.address))
      .then(() => true)
      .catch((err) => {
        console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
      });
  } else if (deployer.network.startsWith('plasma')) {
    const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
    deployer.deploy(TwoKeyPlasmaEvents);
  }
};
