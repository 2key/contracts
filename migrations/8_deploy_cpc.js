const MerkleProof = artifacts.require('MerkleProof');
const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const TwoKeyCPCCampaignPlasma = artifacts.require('TwoKeyCPCCampaignPlasma');
const TwoKeyCPCCampaign = artifacts.require('TwoKeyCPCCampaign');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');



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

const approveVersion = (async(campaignName, contractType, twoKeySingletonesRegistryAddress) => {
    await new Promise(async(resolve,reject) => {
        try {
            let instance = await TwoKeyPlasmaSingletoneRegistry.at(twoKeySingletonesRegistryAddress);
            let version = await instance.getLatestAddedContractVersion(campaignName);

            console.log('Last version: ' + version);
            if(version === "1.0.0") {
                let instance = await TwoKeyPlasmaSingletoneRegistry.at(twoKeySingletonesRegistryAddress);
                console.log("Let's approve all initial versions for campaigns");
                let txHash = await instance.approveCampaignVersionDuringCreation(contractType);
                resolve(txHash);
            } else {
                resolve(true);
            }
        } catch (e) {
            reject(e);
        }
    });
});


module.exports = function deploy(deployer) {

    let version;

    if(deployer.network.startsWith('dev') || deployer.network.startsWith('public')) {
        deployer.link(Call, TwoKeyCPCCampaign);
        deployer.link(MerkleProof, TwoKeyCPCCampaign);
        deployer.deploy(TwoKeyCPCCampaign)
            .then(() => TwoKeyCPCCampaign.deployed())
            .then(async () => {
                version = await addNewContractVersion("TwoKeyCPCCampaign", TwoKeyCPCCampaign.address, TwoKeySingletonesRegistry.address);
            })
            .then(async () => {
                await approveVersion("TwoKeyCPCCampaign", "CPC_PUBLIC", TwoKeySingletonesRegistry.address);
            })
            .then(() => true);
    }
    else if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        //Deploy CPC on plasma network
        deployer.link(Call, TwoKeyCPCCampaignPlasma);
        deployer.link(MerkleProof, TwoKeyCPCCampaignPlasma);
        deployer.deploy(TwoKeyCPCCampaignPlasma)
            .then(() => TwoKeyCPCCampaignPlasma.deployed())
            .then(async() => {
                await addNewContractVersion("TwoKeyCPCCampaignPlasma", TwoKeyCPCCampaignPlasma.address, TwoKeyPlasmaSingletoneRegistry.address);
            })
            .then(async () => {
                await approveVersion("TwoKeyCPCCampaignPlasma", "CPC_PLASMA", TwoKeyPlasmaSingletoneRegistry.address);
            })
            .then(() => true);
    }

}
