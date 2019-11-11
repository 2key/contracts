const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyBaseReputationRegistry = artifacts.require('TwoKeyBaseReputationRegistry');
const TwoKeyParticipationMiningPool = artifacts.require('TwoKeyParticipationMiningPool');
const TwoKeyDeepFreezeTokenPool = artifacts.require('TwoKeyDeepFreezeTokenPool');
const TwoKeyLongTermTokenPool = artifacts.require('TwoKeyLongTermTokenPool');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyFactory = artifacts.require('TwoKeyFactory');
const KyberNetworkTestMockContract = artifacts.require('KyberNetworkTestMockContract');
const TwoKeyMaintainersRegistry = artifacts.require('TwoKeyMaintainersRegistry');
const TwoKeySignatureValidator = artifacts.require('TwoKeySignatureValidator');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyParticipationPaymentsManager = artifacts.require('TwoKeyParticipationPaymentsManager');


const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaRegistry = artifacts.require('TwoKeyPlasmaRegistry');
const TwoKeyPlasmaMaintainersRegistry = artifacts.require('TwoKeyPlasmaMaintainersRegistry');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');

const fs = require('fs');
const path = require('path');
const addressesFile = path.join(__dirname, '../configurationFiles/contractNamesToProxyAddresses.json');
const deploymentConfigFile = path.join(__dirname, '../configurationFiles/deploymentConfig.json');


/**
 * Function to instantiate config files
 * @type {function(*)}
 */
const instantiateConfigs = ((deployer) => {
    let deploymentObject = {};
    if (fs.existsSync(deploymentConfigFile)) {
        deploymentObject = JSON.parse(fs.readFileSync(deploymentConfigFile, {encoding: 'utf8'}));
    }

    let deploymentNetwork;
    if (deployer.network.startsWith('dev') || deployer.network.startsWith('plasma-test')) {
        deploymentNetwork = 'dev-local-environment'
    } else if (deployer.network.startsWith('public') || deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deploymentNetwork = 'ropsten-environment';
    }

    return deploymentObject[deploymentNetwork];
});


/**
 * Get kyber configuration per network
 * @type {function(*, *)}
 */
const setKyberPerNetwork = ((deploymentConfig, network) => {
    if(network.startsWith('dev')) {
        return KyberNetworkTestMockContract.address;
    } else if (network.startsWith('public')) {
        return deploymentConfig.kyberConfig.KYBER_NETWORK_PROXY_ADDRESS_ROPSTEN;
    }
});


module.exports = function deploy(deployer) {

    let deploymentConfig = instantiateConfigs(deployer);

    let contractNameToProxyAddress = {};
    if (fs.existsSync(addressesFile)) {
        contractNameToProxyAddress = JSON.parse(fs.readFileSync(addressesFile, { encoding: 'utf8' }));
    }

    const maintainerAddresses = deploymentConfig.maintainers;
    const coreDevs = deploymentConfig.coreDevs;
    const rewardsReleaseAfter = deploymentConfig.admin2keyReleaseDate; //1 January 2020
    const DAI_ROPSTEN_ADDRESS = '0xaD6D458402F60fD3Bd25163575031ACDce07538D';

    let kyberAddress = setKyberPerNetwork(deploymentConfig, deployer.network);


    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {
        deployer.then(async () => {


            await new Promise(async (resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyMaintainersRegistry');
                    let instance = await TwoKeyMaintainersRegistry.at(contractNameToProxyAddress["TwoKeyMaintainersRegistry"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyMaintainersRegistryStorage"],
                        maintainerAddresses,
                        coreDevs
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async (resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeySignatureValidator');
                    let instance = await TwoKeySignatureValidator.at(contractNameToProxyAddress["TwoKeySignatureValidator"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeySignatureValidatorStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyParticipationMiningPool');
                    let instance = await TwoKeyParticipationMiningPool.at(contractNameToProxyAddress["TwoKeyParticipationMiningPool"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        TwoKeyEconomy.address,
                        contractNameToProxyAddress["TwoKeyParticipationMiningPoolStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });

            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyParticipationPaymentsManager');
                    let instance = await TwoKeyParticipationPaymentsManager.at(contractNameToProxyAddress["TwoKeyParticipationPaymentsManager"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyParticipationPaymentsManagerStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyLongTermTokenPool');
                    let instance = await TwoKeyLongTermTokenPool.at(contractNameToProxyAddress["TwoKeyLongTermTokenPool"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        TwoKeyEconomy.address,
                        contractNameToProxyAddress["TwoKeyLongTermTokenPoolStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyDeepFreezeTokenPool');
                    let instance = await TwoKeyDeepFreezeTokenPool.at(contractNameToProxyAddress["TwoKeyDeepFreezeTokenPool"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        TwoKeyEconomy.address,
                        contractNameToProxyAddress["TwoKeyParticipationMiningPool"],
                        contractNameToProxyAddress["TwoKeyDeepFreezeTokenPoolStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyCampaignValidator');
                    let instance = await TwoKeyCampaignValidator.at(contractNameToProxyAddress["TwoKeyCampaignValidator"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyCampaignValidatorStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyEventSource');
                    let instance = await TwoKeyEventSource.at(contractNameToProxyAddress["TwoKeyEventSource"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyEventSourceStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyBaseReputationRegistry');
                    let instance = await TwoKeyBaseReputationRegistry.at(contractNameToProxyAddress["TwoKeyBaseReputationRegistry"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyBaseReputationRegistryStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyExchangeRateContract');
                    let instance = await TwoKeyExchangeRateContract.at(contractNameToProxyAddress["TwoKeyExchangeRateContract"])
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyExchangeRateStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log(
                        TwoKeyEconomy.address,
                        DAI_ROPSTEN_ADDRESS,
                        kyberAddress,
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyUpgradableExchangeStorage"]
                    );
                    console.log('Setting initial parameters in contract TwoKeyUpgradableExchange');
                    let instance = await TwoKeyUpgradableExchange.at(contractNameToProxyAddress["TwoKeyUpgradableExchange"]);
                    let txHash = instance.setInitialParams(
                        TwoKeyEconomy.address,
                        DAI_ROPSTEN_ADDRESS,
                        kyberAddress,
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyUpgradableExchangeStorage"]
                    );

                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyAdmin');
                    let instance = await TwoKeyAdmin.at(contractNameToProxyAddress["TwoKeyAdmin"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyAdminStorage"],
                        TwoKeyCongress.address,
                        TwoKeyEconomy.address,
                        deployer.network.startsWith('dev') ? 1 : rewardsReleaseAfter
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyFactory');
                    let instance = await TwoKeyFactory.at(contractNameToProxyAddress["TwoKeyFactory"]);
                    let txHash = instance.setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyFactoryStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });


            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyRegistry');
                    let instance = await TwoKeyRegistry.at(contractNameToProxyAddress["TwoKeyRegistry"]);
                    let txHash = instance.setInitialParams
                    (
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyRegistryStorage"]
                    );

                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });
        })
        .then(() => true);
    } else if (deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {

        deployer.then(async() => {


                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in plasma contract on plasma network');
                        let instance = await TwoKeyPlasmaEvents.at(contractNameToProxyAddress["TwoKeyPlasmaEvents"]);
                        let txHash = instance.setInitialParams
                        (
                            TwoKeyPlasmaSingletoneRegistry.address,
                            contractNameToProxyAddress["TwoKeyPlasmaEventsStorage"],
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });


                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in plasma registry contract on plasma network');
                        let instance = await TwoKeyPlasmaRegistry.at(contractNameToProxyAddress["TwoKeyPlasmaRegistry"]);
                        let txHash = instance.setInitialParams
                        (
                            TwoKeyPlasmaSingletoneRegistry.address,
                            contractNameToProxyAddress["TwoKeyPlasmaRegistryStorage"]
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });


                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in Maintainers contract on plasma network');
                        let instance = await TwoKeyPlasmaMaintainersRegistry.at(contractNameToProxyAddress["TwoKeyPlasmaMaintainersRegistry"]);
                        let txHash = instance.setInitialParams
                        (
                            TwoKeyPlasmaSingletoneRegistry.address,
                            contractNameToProxyAddress["TwoKeyPlasmaMaintainersRegistryStorage"],
                            maintainerAddresses
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                });
            })
            .then(() => true)
    }
}
