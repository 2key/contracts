// deploy the following contracts:
// * 2Key Economy, coinbase is the owner
// * 2Key registry
// * sample contract for each type of campagin. Use fake constractor parameters. coinbase is the contractor
var TwoKeySignedAcquisitionContract = artifacts.require('TwoKeySignedAcquisitionContract')
var TwoKeySignedPresellContract = artifacts.require('TwoKeySignedPresellContract')
var TwoKeyCampaign = artifacts.require('TwoKeyCampaign')

const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');

module.exports = function (deployer) {
  if (deployer.network.startsWith('dev')) {
    // deploy sample contracts for type of campaign. We will use registry=0 and erc20=0 to indicate that its only a sample
    deployer.deploy(TwoKeySignedAcquisitionContract, 0, 0, 0, 0, 0, 0, 0, 0, 0, {gas: 5000000})
    deployer.deploy(TwoKeySignedPresellContract, 0, '', '', 0, 0, 0, 0, '', 0, {gas: 5000000})
    // deployer.deploy(TwoKeyCampaign, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, {gas: 9000000})
  }
}
