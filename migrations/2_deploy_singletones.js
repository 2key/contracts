/*// deploy the following contracts:
// * 2Key Economy, coinbase is the owner
// * 2Key registry
// * sample contract for each type of campagin.
// * Use fake constractor parameters. coinbase is the contractor
/* global artifacts */

// const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
// const ERC20TokenMock = artifacts.require('ERC20TokenMock');
// const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
// const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
// const EventSource = artifacts.require('TwoKeyEventSource');
// const TwoKeyReg = artifacts.require('TwoKeyReg');
//
// module.exports = function deploy(deployer) {
//   if (deployer.network.startsWith('dev') || deployer.network === 'rinkeby-infura') {
//       deployer.deploy(ERC20TokenMock)
//       .then(() => deployer.deploy(TwoKeyUpgradableExchange, 1, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', ERC20TokenMock.address))
//       .then(() => TwoKeyUpgradableExchange.deployed())
//       .then(() => deployer.deploy(TwoKeyAdmin, TwoKeyEconomy.address, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', TwoKeyUpgradableExchange.address))
//       .then(() => TwoKeyAdmin.deployed())
//       .then(() => deployer.deploy(EventSource, TwoKeyAdmin.address))
//       .then(() => deployer.deploy(TwoKeyReg, EventSource.address))
//       .then(() => true)
//       .catch((err) => {
//         console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
//       });
//   } else if (deployer.network.startsWith('plasma')) {
//     const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
//     deployer.deploy(TwoKeyPlasmaEvents);
//   }
// };



const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
// const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyReg = artifacts.require('TwoKeyReg');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');

/*
    TwoKeyCongress constructor need 2 addresses passed, the best'd be if we get that addresses static and always save the same ones
 */

module.exports = function deploy(deployer) {
  var adminInstance;
  let initialCongressMembers = ['0xb3fa520368f2df7bed4df5185101f303f6c7decc','0xb3fa520368f2df7bed4df5185101f303f6c7decc'];
  let votingPowers = [1,3];

  if(deployer.network.startsWith('dev') || deployer.network === 'rinkeby-infura' || turdeployer.network == 'ropsten') {
    deployer.deploy(TwoKeyAdmin,'0xb3fa520368f2df7bed4df5185101f303f6c7decc')
        .then(() => TwoKeyAdmin.deployed())
        .then(function(instance) {
            adminInstance = instance;
        })
        .then(() => deployer.deploy(TwoKeyCongress, 1, 50, initialCongressMembers, votingPowers))
        .then(() => deployer.deploy(TwoKeyEconomy, TwoKeyAdmin.address))
        .then(() => deployer.deploy(TwoKeyUpgradableExchange, 1, '0xb3fa520368f2df7bed4df5185101f303f6c7decc', TwoKeyEconomy.address, TwoKeyAdmin.address))
        .then(() => TwoKeyUpgradableExchange.deployed())
        .then(() => deployer.deploy(EventSource, TwoKeyAdmin.address))
        .then(() => EventSource.deployed())
        // .then(() => adminInstance.setTwoKeyExchange(TwoKeyUpgradableExchange.address))
        .then(() => deployer.deploy(TwoKeyReg, EventSource.address, TwoKeyAdmin.address))
        .then(() => TwoKeyReg.deployed())
        .then(() => adminInstance.setSingletones(TwoKeyEconomy.address, TwoKeyUpgradableExchange.address, TwoKeyReg.address, EventSource.address))
        .then(() => true)
        .catch((err) => {
            console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
        });
  } else if(deployer.network.startsWith('plasma')) {
    const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
    deployer.deploy(TwoKeyPlasmaEvents);
  }
};
