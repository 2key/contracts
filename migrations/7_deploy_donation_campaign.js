const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');

const TwoKeyDonationCampaign = artifacts.require('TwoKeyDonationCampaign');
const TwoKeyDonationConversionHandler = artifacts.require('TwoKeyDonationConversionHandler');
const TwoKeyDonationLogicHandler = artifacts.require('TwoKeyDonationLogicHandler');

const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const { incrementVersion } = require('../helpers');


module.exports = function deploy(deployer) {

    let TWO_KEY_SINGLETON_REGISTRY_ADDRESS;
    let version;

    if(deployer.network.startsWith('dev') || deployer.network.startsWith('public')) {
        deployer.link(Call, TwoKeyDonationCampaign)
            .then(() => deployer.deploy(TwoKeyDonationCampaign))
            .then(() => TwoKeyDonationCampaign.deployed())
            .then(() => deployer.deploy(TwoKeyDonationConversionHandler))
            .then(() => TwoKeyDonationConversionHandler.deployed())
            .then(() => deployer.link(IncentiveModels, TwoKeyDonationLogicHandler))
            .then(() => deployer.link(Call, TwoKeyDonationLogicHandler))
            .then(() => deployer.deploy(TwoKeyDonationLogicHandler))
            .then(() => TwoKeyDonationLogicHandler.deployed())
            .then(async () => {
                console.log('... Adding implementation versions of Donation campaigns');
                TWO_KEY_SINGLETON_REGISTRY_ADDRESS = TwoKeySingletonesRegistry.address;
                let instance = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS);

                await new Promise(async(resolve,reject) => {
                    try {
                        version = await instance.getLatestAddedContractVersion("TwoKeyDonationCampaign");
                        version = incrementVersion(version);

                        console.log('Version :' + version);

                        let txHash1 = await instance.addVersion('TwoKeyDonationCampaign', version, TwoKeyDonationCampaign.address);
                        let txHash2 = await instance.addVersion('TwoKeyDonationConversionHandler', version, TwoKeyDonationConversionHandler.address);
                        let txHash3 = await instance.addVersion('TwoKeyDonationLogicHandler', version, TwoKeyDonationLogicHandler.address);

                        resolve({txHash1,txHash2,txHash3});
                    } catch (e) {
                        reject(e);
                    }
                })
            })
            .then(async () => {
                await new Promise(async(resolve,reject) => {
                    try {
                        if(version === "1.0.0") {
                            let instance = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS);
                            console.log("Let's approve initial version of Donation campaign");
                            let txHash = await instance.approveCampaignVersionDuringCreation("DONATION");
                            resolve(txHash);
                        } else {
                            resolve(true);
                        }
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .then(() => true);
    } else if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        console.log('No contracts for selected network');
    }
}
