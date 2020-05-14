const TwoKeyAcquisitionCampaignERC20 = artifacts.require('TwoKeyAcquisitionCampaignERC20');
const TwoKeyConversionHandler = artifacts.require('TwoKeyConversionHandler');
const TwoKeyAcquisitionLogicHandler = artifacts.require('TwoKeyAcquisitionLogicHandler');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyPurchasesHandler = artifacts.require('TwoKeyPurchasesHandler');

const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const { incrementVersion } = require('../helpers');


module.exports = function deploy(deployer) {

    let TWO_KEY_SINGLETON_REGISTRY_ADDRESS;
    let version;

    if(deployer.network.startsWith('dev') || deployer.network.startsWith('public')) {
        // deployer.deploy(TwoKeyConversionHandler)
        //     .then(() => TwoKeyConversionHandler.deployed())
        //     .then(() => deployer.deploy(TwoKeyPurchasesHandler))
        //     .then(() => TwoKeyPurchasesHandler.deployed())
            deployer.link(Call, TwoKeyAcquisitionLogicHandler)
            .then(() => deployer.link(Call, TwoKeyAcquisitionCampaignERC20))
            .then(() => deployer.deploy(TwoKeyAcquisitionLogicHandler))
            .then(() => deployer.deploy(TwoKeyAcquisitionCampaignERC20))
            .then(() => TwoKeyAcquisitionCampaignERC20.deployed())
            .then(() => true)
            .then(async () => {

                TWO_KEY_SINGLETON_REGISTRY_ADDRESS = TwoKeySingletonesRegistry.address;
                let instance = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS);
                console.log("... Adding implementation versions of Acquisition campaigns");
                await new Promise(async(resolve,reject) => {
                    try {

                        version = await instance.getLatestAddedContractVersion("TwoKeyAcquisitionCampaignERC20");
                        version = incrementVersion(version);

                        console.log('Version :' + version);

                        let txHash = await instance.addVersion('TwoKeyAcquisitionLogicHandler', version, TwoKeyAcquisitionLogicHandler.address);
                        let txHash1 = await instance.addVersion('TwoKeyConversionHandler', version, TwoKeyConversionHandler.address);
                        let txHash2 = await instance.addVersion('TwoKeyAcquisitionCampaignERC20', version, TwoKeyAcquisitionCampaignERC20.address);
                        let txHash3 = await instance.addVersion('TwoKeyPurchasesHandler', version, TwoKeyPurchasesHandler.address);

                        resolve({txHash,txHash1,txHash2,txHash3});
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
                            console.log("Let's approve all initial versions for campaigns");
                            let txHash = await instance.approveCampaignVersionDuringCreation("TOKEN_SELL");
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
