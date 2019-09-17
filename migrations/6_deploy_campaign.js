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
const TwoKeyDonationLogicHandler = artifacts.require('TwoKeyDonationLogicHandler');

const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const fs = require('fs');
const path = require('path');

const { incrementVersion, getGitBranch } = require('../helpers');


module.exports = function deploy(deployer) {

    if(!deployer.network.startsWith('private') && !deployer.network.startsWith('plasma')) {
        let TWO_KEY_SINGLETON_REGISTRY_ADDRESS = TwoKeySingletonesRegistry.address;
        if(deployer.network.startsWith('dev')) {
            TWO_KEY_SINGLETON_REGISTRY_ADDRESS = TwoKeySingletonesRegistry.address;
        }

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
        .then(() => deployer.deploy(TwoKeyDonationConversionHandler))
        .then(() => deployer.link(IncentiveModels, TwoKeyDonationLogicHandler))
        .then(() => deployer.link(Call, TwoKeyDonationLogicHandler))
        .then(() => deployer.deploy(TwoKeyDonationLogicHandler))
        .then(() => deployer.link(Call, TwoKeyDonationCampaign))
        .then(() => deployer.deploy(TwoKeyDonationCampaign))
        .then(async () => {
            let instance = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS);
            console.log('... Adding implementation versions of Donation campaigns');
            await new Promise(async(resolve,reject) => {
                try {
                    let version = await instance.getLatestContractVersion("TwoKeyDonationCampaign");

                    version = incrementVersion(version);

                    let txHash = await instance.addVersion('TwoKeyDonationCampaign', version, TwoKeyDonationCampaign.address);
                    txHash = await instance.addVersion('TwoKeyDonationConversionHandler', version, TwoKeyDonationConversionHandler.address);
                    txHash = await instance.addVersion('TwoKeyDonationLogicHandler', version, TwoKeyDonationLogicHandler.address);

                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            })
        })
        .then(async () => {
            let instance = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS);
            console.log("... Adding implementation versions of Acquisition campaigns");
            await new Promise(async(resolve,reject) => {
                try {

                    let version = await instance.getLatestContractVersion("TwoKeyAcquisitionCampaignERC20");
                    version = incrementVersion(version);

                    let txHash = await instance.addVersion('TwoKeyAcquisitionLogicHandler', version, TwoKeyAcquisitionLogicHandler.address);
                    txHash = await instance.addVersion('TwoKeyConversionHandler', version, TwoKeyConversionHandler.address);
                    txHash = await instance.addVersion('TwoKeyAcquisitionCampaignERC20', version, TwoKeyAcquisitionCampaignERC20.address);
                    txHash = await instance.addVersion('TwoKeyPurchasesHandler', version, TwoKeyPurchasesHandler.address);

                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            })
        })
        .then(() => true);
    }

}
