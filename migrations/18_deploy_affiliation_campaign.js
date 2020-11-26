const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const TwoKeyPlasmaAffiliationCampaign = artifacts.require('TwoKeyPlasmaAffiliationCampaign');

const Call = artifacts.require('Call');

const { incrementVersion } = require('../helpers');


module.exports = function deploy(deployer) {

  let TWO_KEY_SINGLETON_REGISTRY_ADDRESS;
  let version;

  if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
    deployer.link(Call, TwoKeyPlasmaAffiliationCampaign)
      .then(() => deployer.deploy(TwoKeyPlasmaAffiliationCampaign))
      .then(async () => {
        console.log('... Adding implementation versions of AFFILIATION campaigns');
        TWO_KEY_SINGLETON_REGISTRY_ADDRESS = TwoKeyPlasmaSingletoneRegistry.address;
        let instance = await TwoKeyPlasmaSingletoneRegistry.at(TWO_KEY_SINGLETON_REGISTRY_ADDRESS);

        await new Promise(async(resolve,reject) => {
          try {
            version = await instance.getLatestAddedContractVersion("TwoKeyPlasmaAffiliationCampaign");
            version = incrementVersion(version);

            console.log('Version :' + version);

            let txHash1 = await instance.addVersion('TwoKeyPlasmaAffiliationCampaign', version, TwoKeyPlasmaAffiliationCampaign.address);
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
              console.log("Approve initial version of affiliation campaign");
              let txHash = await instance.approveCampaignVersionDuringCreation("AFFILIATION_PLASMA");
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
