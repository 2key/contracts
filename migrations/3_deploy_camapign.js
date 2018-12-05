const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyConversionHandler = artifacts.require('TwoKeyConversionHandler');
const TwoKeyCampaignInventory = artifacts.require('TwoKeyCampaignInventory');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const Call = artifacts.require('Call');
const TwoKeyHackEventSource = artifacts.require('TwoKeyHackEventSource');
const TwoKeyExchangeContract = artifacts.require('TwoKeyExchangeContract');
const json = require('../2key-protocol/src/proxyAddresses.json');

module.exports = function deploy(deployer) {
    let networkId;
    if(deployer.network.startsWith('ropsten')) {
        networkId = 3;
    } else if(deployer.network.startsWith('rinkeby')) {
        networkId = 4;
    } else if (deployer.network.startsWith('public')) {
        networkId = 3;
    } else if(deployer.network.startsWith('dev')) {
        networkId = 8086;
    }
    let x = 1;
    if (deployer.network.startsWith('dev') || deployer.network === 'ropsten' || (deployer.network.startsWith('rinkeby-test') && !process.env.DEPLOY)) {
        deployer.deploy(TwoKeyConversionHandler, 1012019, 180, 6, 180)
            .then(() => TwoKeyConversionHandler.deployed())
            .then(() => deployer.deploy(ERC20TokenMock))
            .then(() => deployer.link(Call, TwoKeyAcquisitionCampaignERC20))
            .then(() => deployer.deploy(TwoKeyHackEventSource))
            .then(() => deployer.deploy(TwoKeyAcquisitionCampaignERC20, TwoKeyHackEventSource.address, TwoKeyConversionHandler.address,
                '0xb3fa520368f2df7bed4df5185101f303f6c7decc', ERC20TokenMock.address,
                [12345, 15345, 12345, 5, 5, 5, 5, 12, 15, 1], 'USD', TwoKeyExchangeContract.address))
            .then(() => TwoKeyAcquisitionCampaignERC20.deployed())
            .then(() => true)
            .then(async () => {
                console.log("... Adding TwoKeyAcquisitionCampaign to EventSource");
                await new Promise(async (resolve, reject) => {
                    try {
                        let txHash = await EventSource.at(json.TwoKeyEventSource[networkId.toString()].Proxy).addContract(TwoKeyAcquisitionCampaignERC20.address, {gas: 7000000});
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
                console.log("Added TwoKeyAcquisition: " + TwoKeyAcquisitionCampaignERC20.address + "  to EventSource : " + json.TwoKeyEventSource[networkId.toString()].Proxy + "!");
            }).then(() => true);
    }
}
