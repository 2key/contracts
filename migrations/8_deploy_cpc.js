const MerkleProof = artifacts.require('MerkleProof');
const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const TwoKeyCPCCampaignPlasma = artifacts.require('TwoKeyCPCCampaignPlasma');
const TwoKeyCPCCampaign = artifacts.require('TwoKeyCPCCampaign');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyPlasmaFactoryStorage = artifacts.require('TwoKeyPlasmaFactoryStorage');
const TwoKeyPlasmaFactory = artifacts.require('TwoKeyPlasmaFactory');

const { incrementVersion } = require('../helpers');

const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/proxyAddresses.json');

const INITIAL_VERSION_OF_ALL_SINGLETONS = "1.0.0";

let fileObject = {};
if (fs.existsSync(proxyFile)) {
    fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
}


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

    let flag = false;
    process.argv.forEach((argument) => {
        if(argument === 'create_cpc') {
            flag = true;
        }
    });

    if(flag == false) {
        console.log('No update will be performed');
        return;
    }

    const { network_id } = deployer;
    let version;

    deployer.deploy(MerkleProof);

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
        let proxyLogic;
        let proxyStorage;

        deployer.deploy(TwoKeyPlasmaFactory)
            .then(() => TwoKeyPlasmaFactory.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaFactoryStorage))
            .then(() => TwoKeyPlasmaFactoryStorage.deployed())
            .then(async() => {
                await new Promise(async (resolve, reject) => {
                    try {
                        let registry = await TwoKeyPlasmaSingletoneRegistry.at(TwoKeyPlasmaSingletoneRegistry.address);

                        console.log('-----------------------------------------------------------------------------------');
                        console.log('... Adding TwoKeyPlasmaFactory to Proxy registry as valid implementation');
                        let contractName = "TwoKeyPlasmaFactory";
                        let contractStorageName = "TwoKeyPlasmaFactoryStorage";

                        let txHash = await registry.addVersionDuringCreation(
                            contractName,
                            contractStorageName,
                            TwoKeyPlasmaFactory.address,
                            TwoKeyPlasmaFactoryStorage.address,
                            INITIAL_VERSION_OF_ALL_SINGLETONS
                        );

                        let { logs } = await registry.createProxy(
                            contractName,
                            contractStorageName,
                            INITIAL_VERSION_OF_ALL_SINGLETONS
                        );

                        let { logicProxy, storageProxy } = logs.find(l => l.event === 'ProxiesDeployed').args;

                        proxyLogic = logicProxy;
                        proxyStorage = storageProxy;

                        const jsonObject = fileObject[contractName] || {};
                        jsonObject[network_id] = {
                            'implementationAddressLogic': TwoKeyPlasmaFactory.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyPlasmaFactoryStorage.address,
                            'StorageProxy': storageProxy,
                        };

                        fileObject[contractName] = jsonObject;
                        resolve(logicProxy);
                    } catch (e) {
                        reject(e);
                    }
                });
                fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
            })
            .then(async() => {
                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in TwoKeyPlasmaFactory contract on plasma network');
                        let instance = await TwoKeyPlasmaFactory.at(proxyLogic);
                        let txHash = instance.setInitialParams
                        (
                            TwoKeyPlasmaSingletoneRegistry.address,
                            proxyStorage,
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                    })
            })
            .then(() => deployer.link(Call, TwoKeyCPCCampaignPlasma))
            .then(() => deployer.link(MerkleProof, TwoKeyCPCCampaignPlasma))
            .then(() => deployer.deploy(TwoKeyCPCCampaignPlasma))
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

