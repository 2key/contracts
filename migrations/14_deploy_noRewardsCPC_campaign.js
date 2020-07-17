const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const TwoKeyCPCCampaignPlasmaNoReward = artifacts.require('TwoKeyCPCCampaignPlasmaNoReward');

const Call = artifacts.require('Call');

const { incrementVersion } = require('../helpers');


module.exports = function deploy(deployer) {

    let TWO_KEY_SINGLETON_REGISTRY_ADDRESS;
    let version;

    if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.link(Call, TwoKeyCPCCampaignPlasmaNoReward)
            .then(() => deployer.deploy(TwoKeyCPCCampaignPlasmaNoReward))
            .then(async () => {
                console.log('... Adding implementation versions of CPC NO REWARD campaigns');
                TWO_KEY_SINGLETON_REGISTRY_ADDRESS = TwoKeyPlasmaSingletoneRegistry.address;
                let instance = await TwoKeyPlasmaSingletoneRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS);

                await new Promise(async(resolve,reject) => {
                    try {
                        version = await instance.getLatestAddedContractVersion("TwoKeyCPCCampaignPlasmaNoReward");
                        version = incrementVersion(version);

                        console.log('Version :' + version);

                        let txHash1 = await instance.addVersion('TwoKeyCPCCampaignPlasmaNoReward', version, TwoKeyCPCCampaignPlasmaNoReward.address);
                        resolve({txHash1});
                    } catch (e) {
                        reject(e);
                    }
                })
            })
            .then(async () => {
                await new Promise(async(resolve,reject) => {
                    try {
                        if(version === "1.0.0") {
                            let instance = await TwoKeyPlasmaSingletoneRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS);
                            console.log("Let's approve initial version of CPC NO REWARD campaign");
                            let txHash = await instance.approveCampaignVersionDuringCreation("CPC_NO_REWARDS_PLASMA");
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
    } else {
        console.log('No contracts for selected network');
    }
}
