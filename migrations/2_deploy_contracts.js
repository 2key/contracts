// deploy the following contracts:
// * 2Key Economy, coinbase is the owner
// * 2Key registry
// * sample contract for each type of campagin. Use fake constractor parameters. coinbase is the contractor
var TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
var TwoKeyReg = artifacts.require('TwoKeyReg')

var TwoKeyAcquisitionContract = artifacts.require('TwoKeyAcquisitionContract')
var TwoKeyPresellContract = artifacts.require('TwoKeyPresellContract')

module.exports = function (deployer) {
  // wait for economy and registry contracts to be installed. we need their address for creating valid campaigns
  Promise.all([deployer.deploy(TwoKeyEconomy), deployer.deploy(TwoKeyReg)]).then(() => {
    let id = setInterval(deploy_samples, 500)
    function deploy_samples () {
      if (TwoKeyReg.address && TwoKeyReg.address) {
        deployer.deploy(TwoKeyAcquisitionContract, TwoKeyReg.address, 'Hats', 'HA',
          100000000000, 100000000000,  // unit cost is 0.1ETH and bounty is 0.01ETH
          100000000000000000, 10000000000000000, 10, '', // unlimited ARCs and quota, units=10, no description
          {gas: 4000000})

        deployer.deploy(TwoKeyPresellContract, TwoKeyReg.address, '2Key Presell', '2KP',
          100000000000, 100000000000,  // unit cost is 0.1ETH and bounty is 0.01ETH
          100000000000000000, 10000000000000000, '', // unlimited ARCs and quota, no description
          TwoKeyEconomy.address, // the campaign is for selling tokens in 2Key Economoy
          {gas: 5000000})

        clearInterval(id);
      }
    }
  })
}
