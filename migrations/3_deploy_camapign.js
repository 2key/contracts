const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyConversionHandler = artifacts.require('TwoKeyConversionHandler');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const Call = artifacts.require('Call');
const TwoKeyHackEventSource = artifacts.require('TwoKeyHackEventSource');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAcquisitionLogicHandler = artifacts.require('TwoKeyAcquisitionLogicHandler');

const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');


module.exports = function deploy(deployer) {
    if(!deployer.network.startsWith('private')) {
        let networkId;
        if (deployer.network.startsWith('ropsten')) {
            networkId = 3;
        } else if (deployer.network.startsWith('rinkeby')) {
            networkId = 4;
        } else if (deployer.network.startsWith('public')) {
            networkId = 3;
        } else if (deployer.network.startsWith('dev-local')) {
            networkId = 8086;
        } else if (deployer.network.startsWith('development')) {
            networkId = 'ganache';
        }
        console.log(networkId);
        let x = 1;
        let json = JSON.parse(fs.readFileSync(proxyFile, {encoding: 'utf-8'}));
        deployer.deploy(TwoKeyConversionHandler, 1012019, 180, 6, 180)
            .then(() => TwoKeyConversionHandler.deployed())
            .then(() => deployer.deploy(ERC20TokenMock))
            .then(() => deployer.link(Call, TwoKeyAcquisitionCampaignERC20))
            .then(() => deployer.deploy(TwoKeyAcquisitionLogicHandler,
                12, 15, 1, 12345, 15345, 'USD',
                json.TwoKeyExchangeRateContract[networkId.toString()].Proxy,
                ERC20TokenMock.address))
            .then(() => deployer.deploy(TwoKeyAcquisitionCampaignERC20,
                TwoKeyAcquisitionLogicHandler.address,
                json.TwoKeyEventSource[networkId.toString()].Proxy,
                TwoKeyConversionHandler.address,
                '0xb3fa520368f2df7bed4df5185101f303f6c7decc',
                ERC20TokenMock.address,
                [12345, 5, 5, 5,1],
                json.TwoKeyUpgradableExchange[networkId.toString()].Proxy)
            )
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
            })
            .then(async () => {
                console.log("... Adding TwoKeyAcquisitionCampaign to be eligible to buy tokens from Upgradable Exchange");
                await new Promise(async (resolve,reject) => {
                    try {
                        let txHash = await TwoKeyUpgradableExchange.at(json.TwoKeyUpgradableExchange[networkId.toString()].Proxy)
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
