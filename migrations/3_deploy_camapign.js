const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const TwoKeyConversionHandler = artifacts.require('TwoKeyConversionHandler');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAcquisitionLogicHandler = artifacts.require('TwoKeyAcquisitionLogicHandler');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyDonationCampaign = artifacts.require('TwoKeyDonationCampaign');
const TwoKeyDonationConversionHandler = artifacts.require('TwoKeyDonationConversionHandler');
const TwoKeyPurchasesHandler = artifacts.require('TwoKeyPurchasesHandler');
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
        deployer.deploy(TwoKeyConversionHandler)
        .then(() => TwoKeyConversionHandler.deployed())
        .then(() => deployer.deploy(TwoKeyPurchasesHandler))
        .then(() => TwoKeyPurchasesHandler.deployed())
        .then(() => deployer.link(Call, TwoKeyAcquisitionLogicHandler))
        .then(() => deployer.link(Call, TwoKeyAcquisitionCampaignERC20))
        .then(() => deployer.deploy(TwoKeyAcquisitionLogicHandler))
        .then(() => deployer.deploy(TwoKeyAcquisitionCampaignERC20))
        .then(() => TwoKeyAcquisitionCampaignERC20.deployed())
        .then(() => true)
        .then(() => deployer.deploy(TwoKeyDonationConversionHandler,
            'Nikoloken',
            'NTKN',
            ))
        .then(() => deployer.link(IncentiveModels, TwoKeyDonationCampaign))
        .then(() => deployer.link(Call, TwoKeyDonationCampaign))
        .then(() => deployer.deploy(TwoKeyDonationCampaign))
            // json.TwoKeyAdmin[network_id].Proxy,
            // 'Donation for Something',
            // [
            //     5,
            //     12345,
            //     1231112,
            //     10000,
            //     100000000,
            //     10000000000000,
            //     5
            // ],
            // false,
            // false,
            // false,
            // TwoKeySingletonesRegistry.address,
            // TwoKeyDonationConversionHandler.address,
            // 0
            // ))
        .then(async () => {
            console.log("... Adding implementation versions of Acquisition campaigns");
            await new Promise(async(resolve,reject) => {
                try {
                    let txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                        .addVersion('TwoKeyAcquisitionLogicHandler', '1.4', TwoKeyAcquisitionLogicHandler.address);

                    txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                        .addVersion('TwoKeyConversionHandler', '1.4', TwoKeyConversionHandler.address);

                    txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                        .addVersion('TwoKeyAcquisitionCampaignERC20', '1.4', TwoKeyAcquisitionCampaignERC20.address);

                    txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                        .addVersion('TwoKeyPurchasesHandler', '1.4', TwoKeyPurchasesHandler.address);

                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            })
        })
        .then(async () => {
            console.log('... Adding implementation versions of Donation campaigns');
            await new Promise(async(resolve,reject) => {
                try {
                    let txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                        .addVersion('TwoKeyDonationCampaign','1.6', TwoKeyDonationCampaign.address);
                    txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                        .addVersion('TwoKeyDonationConversionHandler', '1.6', TwoKeyDonationConversionHandler.address);

                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            })
        })
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
                                TwoKeyDonationConversionHandler.address
                            ],
                            [
                                '0x54776f4b65794163717569736974696f6e43616d706169676e00000000000000', //TwoKeyAcquisitionCampaign
                                '0x54776f4b6579436f6e76657273696f6e48616e646c6572000000000000000000', //TwoKeyConversionHandler
                                '0x54776f4b65794163717569736974696f6e4c6f67696348616e646c6572000000', //TwoKeyAcquisitionLogicHandler
                                '0x54776f4b6579446f6e6174696f6e43616d706169676e00000000000000000000', //TwoKeyDonationCampaign
                                '0x54776f4b6579446f6e6174696f6e436f6e76657273696f6e48616e646c657200'  //TwoKeyDonationConversionHandler
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
