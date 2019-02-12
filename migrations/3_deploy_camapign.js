const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyConversionHandler = artifacts.require('TwoKeyConversionHandler');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const Call = artifacts.require('Call');
const TwoKeyHackEventSource = artifacts.require('TwoKeyHackEventSource');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAcquisitionLogicHandler = artifacts.require('TwoKeyAcquisitionLogicHandler');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');


module.exports = function deploy(deployer) {
    if(!deployer.network.startsWith('private') && !deployer.network.startsWith('plasma')) {
        const { network_id } = deployer;
        let x = 1;
        let json = JSON.parse(fs.readFileSync(proxyFile, {encoding: 'utf-8'}));
        deployer.deploy(TwoKeyConversionHandler, 12345, 1012019, 180, 6, 180)
            .then(() => TwoKeyConversionHandler.deployed())
            .then(() => deployer.deploy(ERC20TokenMock))
            .then(() => deployer.link(Call, TwoKeyAcquisitionCampaignERC20))
            .then(() => deployer.deploy(TwoKeyAcquisitionLogicHandler,
                12, 15, 1, 12345, 15345, 5, 'USD',
                ERC20TokenMock.address, json.TwoKeyAdmin[network_id].Proxy))
            .then(() => deployer.deploy(
                TwoKeyAcquisitionCampaignERC20,
                TwoKeySingletonesRegistry.address,
                TwoKeyAcquisitionLogicHandler.address,
                TwoKeyConversionHandler.address,
                json.TwoKeyAdmin[network_id].Proxy,
                ERC20TokenMock.address,
                [5, 1],
                )
            )
            .then(() => TwoKeyAcquisitionCampaignERC20.deployed())
            .then(() => true)
            .then(async () => {
                console.log("... Adding TwoKeyAcquisitionCampaign to EventSource");
                await new Promise(async (resolve, reject) => {
                    try {
                        let txHash = await EventSource.at(json.TwoKeyEventSource[network_id].Proxy).addContract(TwoKeyAcquisitionCampaignERC20.address, {gas: 7000000});
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
                console.log("Added TwoKeyAcquisition: " + TwoKeyAcquisitionCampaignERC20.address + "  to EventSource : " + json.TwoKeyEventSource[network_id].Proxy + "!");
            })
            .then(async () => {
                console.log("... Adding TwoKeyAcquisitionCampaign to be eligible to buy tokens from Upgradable Exchange");
                await new Promise(async (resolve,reject) => {
                    try {
                        let txHash = await TwoKeyUpgradableExchange.at(json.TwoKeyUpgradableExchange[network_id].Proxy)
                            .addContractToBeEligibleToBuyTokens(TwoKeyAcquisitionCampaignERC20.address);
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })
            .then(() => true);
    }
}
