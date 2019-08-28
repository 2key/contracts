const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const TwoKeyEventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyBaseReputationRegistry = artifacts.require('TwoKeyBaseReputationRegistry');
const TwoKeyCommunityTokenPool = artifacts.require('TwoKeyCommunityTokenPool');
const TwoKeyDeepFreezeTokenPool = artifacts.require('TwoKeyDeepFreezeTokenPool');
const TwoKeyLongTermTokenPool = artifacts.require('TwoKeyLongTermTokenPool');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const TwoKeyFactory = artifacts.require('TwoKeyFactory');
const KyberNetworkTestMockContract = artifacts.require('KyberNetworkTestMockContract');
const TwoKeyMaintainersRegistry = artifacts.require('TwoKeyMaintainersRegistry');
const TwoKeySignatureValidator = artifacts.require('TwoKeySignatureValidator');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');

const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeyPlasmaRegistry = artifacts.require('TwoKeyPlasmaRegistry');
const TwoKeyPlasmaMaintainersRegistry = artifacts.require('TwoKeyPlasmaMaintainersRegistry');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');

const fs = require('fs');
const path = require('path');
const addressesFile = path.join(__dirname, '../configurationFiles/contractNamesToProxyAddresses.json');
const deploymentConfigFile = path.join(__dirname, '../configurationFiles/deploymentConfig.json');


module.exports = function deploy(deployer) {

    let deploymentObject = {};
    if( fs.existsSync(deploymentConfigFile)) {
        deploymentObject = JSON.parse(fs.readFileSync(deploymentConfigFile, {encoding: 'utf8'}));
    }

    let deploymentNetwork;
    if(deployer.network.startsWith('dev') || deployer.network.startsWith('plasma-test')) {
        deploymentNetwork = 'dev-local-environment'
    } else if (deployer.network.startsWith('public') || deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deploymentNetwork = 'ropsten-environment';
    }

    let contractNameToProxyAddress = {};

    if (fs.existsSync(addressesFile)) {
        contractNameToProxyAddress = JSON.parse(fs.readFileSync(addressesFile, { encoding: 'utf8' }));
    }

    const maintainerAddresses = deploymentObject[deploymentNetwork].maintainers;
    const rewardsReleaseAfter = deploymentObject[deploymentNetwork].admin2keyReleaseDate; //1 January 2020
    const KYBER_NETWORK_PROXY_ADDRESS_ROPSTEN = '0x818E6FECD516Ecc3849DAf6845e3EC868087B755';
    const DAI_ROPSTEN_ADDRESS = '0xaD6D458402F60fD3Bd25163575031ACDce07538D';

    let kyberAddress;

    if(deployer.network.startsWith('dev')) {
        kyberAddress = KyberNetworkTestMockContract.address;
    } else {
        kyberAddress = KYBER_NETWORK_PROXY_ADDRESS_ROPSTEN;
    }

    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('ropsten')) {
        deployer.then(async () => {
            await new Promise(async (resolve,reject) => {
                try {
                    console.log('----------------------------------------------------------------');
                    console.log('Setting initial parameters in contract TwoKeyMaintainersRegistry');
                    let txHash = await TwoKeyMaintainersRegistry.at(contractNameToProxyAddress["TwoKeyMaintainersRegistry"]).setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        contractNameToProxyAddress["TwoKeyMaintainersRegistryStorage"],
                        maintainerAddresses
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });

            await new Promise(async (resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeySignatureValidator');
                    let txHash = await TwoKeySignatureValidator.at(contractNameToProxyAddress["TwoKeySignatureValidator"]).setInitialParams(
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
                    console.log('Setting initial parameters in contract TwoKeyCommunityTokenPool');
                    let txHash = await TwoKeyCommunityTokenPool.at(contractNameToProxyAddress["TwoKeyCommunityTokenPool"]).setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        TwoKeyEconomy.address,
                        contractNameToProxyAddress["TwoKeyCommunityTokenPoolStorage"]
                    );
                    resolve(txHash);
                } catch (e) {
                    reject(e);
                }
            });

            await new Promise(async(resolve,reject) => {
                try {
                    console.log('Setting initial parameters in contract TwoKeyLongTermTokenPool');
                    let txHash = await TwoKeyLongTermTokenPool.at(contractNameToProxyAddress["TwoKeyLongTermTokenPool"]).setInitialParams(
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
                    let txHash = await TwoKeyDeepFreezeTokenPool.at(contractNameToProxyAddress["TwoKeyDeepFreezeTokenPool"]).setInitialParams(
                        TwoKeySingletonesRegistry.address,
                        TwoKeyEconomy.address,
                        contractNameToProxyAddress["TwoKeyCommunityTokenPool"],
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
                    let txHash = await TwoKeyCampaignValidator.at(contractNameToProxyAddress["TwoKeyCampaignValidator"]).setInitialParams(
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
                    let txHash = await TwoKeyEventSource.at(contractNameToProxyAddress["TwoKeyEventSource"]).setInitialParams(
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
                    let txHash = await TwoKeyBaseReputationRegistry.at(contractNameToProxyAddress["TwoKeyBaseReputationRegistry"]).setInitialParams(
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
                    let txHash = await TwoKeyExchangeRateContract.at(contractNameToProxyAddress["TwoKeyExchangeRateContract"]).setInitialParams(
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
                    console.log('Setting initial parameters in contract TwoKeyUpgradableExchange');
                    let txHash = await TwoKeyUpgradableExchange.at(contractNameToProxyAddress["TwoKeyUpgradableExchange"]).setInitialParams(
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
                    let txHash = await TwoKeyAdmin.at(contractNameToProxyAddress["TwoKeyAdmin"]).setInitialParams(
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
                    let txHash = await TwoKeyFactory.at(contractNameToProxyAddress["TwoKeyFactory"]).setInitialParams(
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
                    let txHash = await TwoKeyRegistry.at(contractNameToProxyAddress["TwoKeyRegistry"]).setInitialParams
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
                        let txHash = await TwoKeyPlasmaEvents.at(contractNameToProxyAddress["TwoKeyPlasmaEvents"]).setInitialParams
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
                        let txHash = await TwoKeyPlasmaRegistry.at(contractNameToProxyAddress["TwoKeyPlasmaRegistry"]).setInitialParams
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
                        let txHash = await TwoKeyPlasmaMaintainersRegistry.at(contractNameToProxyAddress["TwoKeyPlasmaMaintainersRegistry"]).setInitialParams
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
