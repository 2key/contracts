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

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');


let TWO_KEY_SINGLETON_REGISTRY_ADDRESS = "0x20a20172f22120f966530bb853e395f1682bb414";


/**
 * Function to increment minor version
 * @type {function(*)}
 */
const incrementVersion = ((version) => {
    if(version == "") {
        version = "1.0.0";
    }
    let vParts = version.split('.');
    if(vParts.length < 2) {
        vParts = "1.0.0".split('.');
    }
    // assign each substring a position within our array
    let partsArray = {
        major : vParts[0],
        minor : vParts[1],
        patch : vParts[2]
    };
    // target the substring we want to increment on
    partsArray.patch = parseFloat(partsArray.patch) + 1;
    // set an empty array to join our substring values back to
    let vArray = [];
    // grabs each property inside our partsArray object
    for (let prop in partsArray) {
        if (partsArray.hasOwnProperty(prop)) {
            // add each property to the end of our new array
            vArray.push(partsArray[prop]);
        }
    }
    // join everything back into one string with a period between each new property
    let newVersion = vArray.join('.');
    return newVersion;
});

module.exports = function deploy(deployer) {
    if(!deployer.network.startsWith('private') && !deployer.network.startsWith('plasma')) {
        if(deployer.network.startsWith('dev')) {
            TWO_KEY_SINGLETON_REGISTRY_ADDRESS = TwoKeySingletonesRegistry.address;
        }
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
        .then(() => deployer.deploy(TwoKeyDonationConversionHandler))
        .then(() => deployer.link(IncentiveModels, TwoKeyDonationLogicHandler))
        .then(() => deployer.link(Call, TwoKeyDonationLogicHandler))
        .then(() => deployer.deploy(TwoKeyDonationLogicHandler))
        .then(() => deployer.link(Call, TwoKeyDonationCampaign))
        .then(() => deployer.deploy(TwoKeyDonationCampaign))
        .then(async () => {
            console.log("... Adding implementation versions of Acquisition campaigns");
            await new Promise(async(resolve,reject) => {
                try {
                    // let version = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS).getLatestContractVersion("TwoKeyAcquisitionCampaignERC20");
                    //
                    // version = incrementVersion(version);
                    let version = "1.0.0";

                    let txHash = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS)
                        .addVersion('TwoKeyAcquisitionLogicHandler', version, TwoKeyAcquisitionLogicHandler.address);

                    txHash = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS)
                        .addVersion('TwoKeyConversionHandler', version, TwoKeyConversionHandler.address);

                    txHash = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS)
                        .addVersion('TwoKeyAcquisitionCampaignERC20', version, TwoKeyAcquisitionCampaignERC20.address);

                    txHash = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS)
                        .addVersion('TwoKeyPurchasesHandler', version, TwoKeyPurchasesHandler.address);

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
                    // let version = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS).getLatestContractVersion("TwoKeyDonationCampaign");
                    //
                    // version = incrementVersion(version);

                    let version = "1.0.0";

                    let txHash = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS)
                        .addVersion('TwoKeyDonationCampaign', version, TwoKeyDonationCampaign.address);

                    txHash = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS)
                        .addVersion('TwoKeyDonationConversionHandler', version, TwoKeyDonationConversionHandler.address);

                    txHash = await TwoKeySingletonesRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS)
                        .addVersion('TwoKeyDonationLogicHandler', version, TwoKeyDonationLogicHandler.address);

                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            })
        })
        .then(() => true);
    }

}
