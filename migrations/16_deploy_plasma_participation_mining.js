const TwoKeyPlasmaParticipationRewards = artifacts.require('TwoKeyPlasmaParticipationRewards');
const TwoKeyPlasmaParticipationRewardsStorage = artifacts.require('TwoKeyPlasmaParticipationRewardsStorage');


const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');

const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/proxyAddresses.json');

const INITIAL_VERSION_OF_ALL_SINGLETONS = "1.0.0";

let fileObject = {};
if (fs.existsSync(proxyFile)) {
    fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
}

/**
 * Script which will be called only once to add new contract to the system
 * @param deployer
 */

module.exports = function deploy(deployer) {

    const { network_id } = deployer;

    let proxyLogic;
    let proxyStorage;

    if(deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        console.log('Deploying private (plasma)  version of TwoKeyPlasmaParticipationRewards contract');
        deployer.deploy(TwoKeyPlasmaParticipationRewards)
            .then(() => TwoKeyPlasmaParticipationRewards.deployed())
            .then(() => deployer.deploy(TwoKeyPlasmaParticipationRewardsStorage))
            .then(() => TwoKeyPlasmaParticipationRewardsStorage.deployed())
            .then(async () => {
                await new Promise(async (resolve, reject) => {
                    try {
                        let registry = await TwoKeyPlasmaSingletoneRegistry.at(TwoKeyPlasmaSingletoneRegistry.address);

                        console.log('-----------------------------------------------------------------------------------');
                        console.log('... Adding TwoKeyPlasmaParticipationRewards to Proxy registry as valid implementation');
                        let contractName = "TwoKeyPlasmaParticipationRewards";
                        let contractStorageName = "TwoKeyPlasmaParticipationRewardsStorage";

                        let txHash = await registry.addVersionDuringCreation(
                            contractName,
                            contractStorageName,
                            TwoKeyPlasmaParticipationRewards.address,
                            TwoKeyPlasmaParticipationRewardsStorage.address,
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
                            'implementationAddressLogic': TwoKeyPlasmaParticipationRewards.address,
                            'Proxy': logicProxy,
                            'implementationAddressStorage': TwoKeyPlasmaParticipationRewardsStorage.address,
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
            .then(async () => {
                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in TwoKeyPlasmaParticipationRewards contract on plasma network');
                        let instance = await TwoKeyPlasmaParticipationRewards.at(proxyLogic);
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
            .then(() => true);
    }
};


