// deploy the following contracts:
// * 2Key Economy, coinbase is the owner
// * 2Key registry
// * sample contract for each type of campagin.
// * Use fake constractor parameters. coinbase is the contractor
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');

module.exports = async function (deployer) {
  if (deployer.network.startsWith('dev') || deployer.network == 'rinkeby-infura') {
    const economy = await deployer.deploy(TwoKeyEconomy);
    const erc20 = await deployer.deploy(ERC20TokenMock);
    const twoKeyUpgradableExchange = await deployer.deploy(TwoKeyUpgradableExchange, 1, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', erc20.address);
    deployer.deploy(TwoKeyAdmin, economy, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', twoKeyUpgradableExchange);
  } else if (deployer.network.startsWith('plasma')) {
    const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
    deployer.deploy(TwoKeyPlasmaEvents);
  }
};
