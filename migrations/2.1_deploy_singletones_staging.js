const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const Call = artifacts.require('Call');
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');

/*

1. deploy electorate contract of admins, giving initial directors' addresses
2. deploy admin contract giving the electorate as param
3. deploy economy contract, giving the admin contract as param
4. deploy upgradable exchange, giving economy contract (not mocktoken), admin contract as params
5. update admin with upgradable exchange contract
6. deploy eventsource with twokeyadmin as param
7. deploy twokeyreg with twokeyadmin, eventsource as params

 */

module.exports = function deploy(deployer) {
  deployer.deploy(Call);
  if (deployer.network === 'staging') {
    deployer.deploy(ERC20TokenMock)
      .then(() => ERC20TokenMock.deployed())  //no need for tokenmock --?> this is actually the twokeyeconomy in the singletons
      .then(() => deployer.deploy(TwoKeyAdmin, '0xb3fa520368f2df7bed4df5185101f303f6c7decc'))
      .then(() => TwoKeyAdmin.deployed())
      .then(() => deployer.deploy(TwoKeyUpgradableExchange, 1, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', ERC20TokenMock.address,TwoKeyAdmin.address))
      .then(() => TwoKeyUpgradableExchange.deployed())
      .then(() => deployer.deploy(TwoKeyEconomy, TwoKeyAdmin.address))
      .then(() => deployer.deploy(EventSource, TwoKeyAdmin.address))
      .then(() => deployer.deploy(TwoKeyRegistry, EventSource.address, TwoKeyAdmin.address))
      .then(() => true)
      .catch((err) => {
        console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
      });
  } else if (deployer.network.startsWith('plasma')) {
      deployer.link(Call,TwoKeyPlasmaEvents);
      deployer.deploy(TwoKeyPlasmaEvents);

  }

};
