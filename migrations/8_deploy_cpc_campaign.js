const MerkleProof = artifacts.require('MerkleProof');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const TwoKeyCPCCampaignPlasma = artifacts.require('TwoKeyCPCCampaignPlasma');
const TwoKeyCPCCampaign = artifacts.require('TwoKeyCPCCampaign');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const IncentiveModels = artifacts.require('IncentiveModels');
const Call = artifacts.require('Call');

const { incrementVersion } = require('../helpers');


const addNewContractVersion = (async (campaignName, deployedAddress, twoKeySingletonRegistryAddress) => {
    console.log('... Adding implementation versions of CPC Campaign');

    let instance = await TwoKeyPlasmaSingletoneRegistry.at(twoKeySingletonRegistryAddress);

    await new Promise(async(resolve,reject) => {
        try {
            let version = await instance.getLatestAddedContractVersion(campaignName);
            version = incrementVersion(version);

            console.log('Version :' + version);
            let txHash = await instance.addVersion(campaignName, version, deployedAddress);

            resolve(txHash);
        } catch (e) {
            reject(e);
        }
    })
});

module.exports = function deploy(deployer) {

    let flag = false;
    process.argv.forEach((argument) => {
        if(argument === 'update_cpc') {
            flag = true;
        }
    });

    if (flag === false) {
        console.log('No update will be performed');
        return;
    }

    if(deployer.network.startsWith('dev') || deployer.network.startsWith('public')) {
        deployer.link(Call, TwoKeyCPCCampaign);
        deployer.link(MerkleProof, TwoKeyCPCCampaign);
        deployer.deploy(TwoKeyCPCCampaign)
            .then(() => TwoKeyCPCCampaign.deployed())
            .then(async () => {
                await addNewContractVersion("TwoKeyCPCCampaign", TwoKeyCPCCampaign.address, TwoKeySingletonesRegistry.address);
            })

            .then(() => true);
    }
    else if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.link(Call, TwoKeyCPCCampaignPlasma);
        deployer.link(MerkleProof, TwoKeyCPCCampaignPlasma);
        deployer.link(IncentiveModels, TwoKeyCPCCampaignPlasma);
        deployer.deploy(TwoKeyCPCCampaignPlasma)
            .then(() => TwoKeyCPCCampaignPlasma.deployed())
            .then(async() => {
                await addNewContractVersion("TwoKeyCPCCampaignPlasma", TwoKeyCPCCampaignPlasma.address, TwoKeyPlasmaSingletoneRegistry.address);
            })
            .then(() => true);
    }
}


