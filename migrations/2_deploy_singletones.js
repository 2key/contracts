// deploy the following contracts:
// * 2Key Economy, coinbase is the owner
// * 2Key registry
// * sample contract for each type of campagin.
// * Use fake constractor parameters. coinbase is the contractor
/* global artifacts */
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');

module.exports = function deploy(deployer) {
  if (deployer.network.startsWith('dev') || deployer.network === 'rinkeby-infura') {
    deployer.deploy(TwoKeyEconomy)
      .then(() => deployer.deploy(ERC20TokenMock))
      .then(() => deployer.deploy(TwoKeyUpgradableExchange, 1, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', ERC20TokenMock.address))
      .then(() => TwoKeyUpgradableExchange.deployed())
      .then(() => deployer.deploy(TwoKeyAdmin, TwoKeyEconomy.address, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', TwoKeyUpgradableExchange.address))
      .then(() => TwoKeyAdmin.deployed())
      .then(() => true)
      .catch((err) => {
        console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
      });
    // const economy = await deployer.deploy(TwoKeyEconomy);
    // const erc20 = await deployer.deploy(ERC20TokenMock);
    // const twoKeyUpgradableExchange = await deployer.deploy(TwoKeyUpgradableExchange, 1, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', erc20.address);
    // console.log(twoKeyUpgradableExchange.address, economy.address);
    // await deployer.deploy(TwoKeyAdmin, economy, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', twoKeyUpgradableExchange);

    // deployer.then(async () => {
    //   const economy = await deployer.deploy(TwoKeyEconomy);
    //   console.log(economy.address);
    //   // const erc20 = await deployer.deploy(ERC20TokenMock);
    //   // const twoKeyUpgradableExchange = await deployer.deploy(TwoKeyUpgradableExchange, 1, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', erc20.address);
    //   // console.log(twoKeyUpgradableExchange.address, economy.address);
    //   // await deployer.deploy(TwoKeyAdmin, economy, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', twoKeyUpgradableExchange);
    // });
  } else if (deployer.network.startsWith('plasma')) {
    const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
    deployer.deploy(TwoKeyPlasmaEvents);
  }
};
