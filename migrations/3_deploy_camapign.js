const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyConversionHandler = artifacts.require('TwoKeyConversionHandler');
const ERC20TokenMock = artifacts.require('ERC20TokenMock');
const TwoKeyHackEventSource = artifacts.require('TwoKeyHackEventSource');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAcquisitionLogicHandler = artifacts.require('TwoKeyAcquisitionLogicHandler');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyDonationCampaign = artifacts.require('TwoKeyDonationCampaign');

const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');


module.exports = function deploy(deployer) {
    if(!deployer.network.startsWith('private') && !deployer.network.startsWith('plasma')) {
        const { network_id } = deployer;
        let x = 1;
        let json = JSON.parse(fs.readFileSync(proxyFile, {encoding: 'utf-8'}));
        deployer.deploy(TwoKeyConversionHandler,
            12345, 1012019, 180, 6, 180)
            .then(() => TwoKeyConversionHandler.deployed())
            .then(() => deployer.deploy(ERC20TokenMock))
            .then(() => deployer.link(Call, TwoKeyAcquisitionLogicHandler))
            .then(() => deployer.link(Call, TwoKeyAcquisitionCampaignERC20))
            .then(() => deployer.deploy(TwoKeyAcquisitionLogicHandler,
                12, 15, 1, 12345, 15345, 5, 'USD',
                ERC20TokenMock.address, json.TwoKeyAdmin[network_id].Proxy))
            .then(() => deployer.deploy(TwoKeyAcquisitionCampaignERC20,
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
            .then(() => deployer.link(IncentiveModels, TwoKeyDonationCampaign))
            .then(() => deployer.link(Call, TwoKeyDonationCampaign))
            .then(() => deployer.deploy(TwoKeyDonationCampaign,
                json.TwoKeyAdmin[network_id].Proxy,
                'Donation for Something',
                'QmABC',
                'QmABCD',
                'Nikoloken',
                'NTKN',
                5,
                12345,
                1231112,
                10000,
                100000000,
                10000000000000,
                5,
                false,
                false,
                TwoKeySingletonesRegistry.address,
                0
                ))
            .then(async () => {
                console.log("... Adding TwoKeyAcquisitionCampaign bytecodes to be valid in the TwoKeyValidator contract");
                await new Promise(async (resolve, reject) => {
                    try {
                        let txHash = await TwoKeyCampaignValidator.at(json.TwoKeyCampaignValidator[network_id].Proxy)
                            .addValidBytecodes(
                                [
                                    TwoKeyAcquisitionCampaignERC20.address,
                                    TwoKeyConversionHandler.address,
                                    TwoKeyAcquisitionLogicHandler.address,
                                    TwoKeyDonationCampaign.address,
                                ],
                                [
                                    '0x54574f5f4b45595f4143515549534954494f4e5f43414d504149474e00000000',
                                    '0x54574f5f4b45595f434f4e56455253494f4e5f48414e444c4552000000000000',
                                    '0x54574f5f4b45595f4143515549534954494f4e5f4c4f4749435f48414e444c45',
                                    '0x54776f4b6579446f6e6174696f6e43616d706169676e00000000000000000000',
                                ]
                            );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .then(() => true);
    }
}
