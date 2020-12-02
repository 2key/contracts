const TwoKeyAffiliationCampaignsPaymentsHandler = artifacts.require('TwoKeyAffiliationCampaignsPaymentsHandler');
const TwoKeyAffiliationCampaignsPaymentsHandlerStorage = artifacts.require('TwoKeyAffiliationCampaignsPaymentsHandlerStorage');

const TwoKeyPlasmaAffiliationCampaignsPaymentsHandler = artifacts.require('TwoKeyPlasmaAffiliationCampaignsPaymentsHandler');
const TwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage = artifacts.require('TwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage');

const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');

const Call = artifacts.require('Call');

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

  if(deployer.network.startsWith('public') || deployer.network.startsWith('dev-local')) {
    console.log('Deploying public version of TwoKeyAffiliationCampaignsPaymentsHandler contract');
    deployer.link(Call, TwoKeyAffiliationCampaignsPaymentsHandler)
      .then(() => deployer.deploy(TwoKeyAffiliationCampaignsPaymentsHandler))
      .then(() => TwoKeyAffiliationCampaignsPaymentsHandler.deployed())
      .then(() => deployer.deploy(TwoKeyAffiliationCampaignsPaymentsHandlerStorage))
      .then(() => TwoKeyAffiliationCampaignsPaymentsHandlerStorage.deployed())
      .then(async () => {
        await new Promise(async (resolve, reject) => {
          try {
            let registry = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address);

            console.log('-----------------------------------------------------------------------------------');
            console.log('... Adding TwoKeyAffiliationCampaignsPaymentsHandler to Proxy registry as valid implementation');
            let contractName = "TwoKeyAffiliationCampaignsPaymentsHandler";
            let contractStorageName = "TwoKeyAffiliationCampaignsPaymentsHandlerStorage";

            await registry.addVersionDuringCreation(
              contractName,
              contractStorageName,
              TwoKeyAffiliationCampaignsPaymentsHandler.address,
              TwoKeyAffiliationCampaignsPaymentsHandlerStorage.address,
              INITIAL_VERSION_OF_ALL_SINGLETONS
            );

            let {logs} = await registry.createProxy(
              contractName,
              contractStorageName,
              INITIAL_VERSION_OF_ALL_SINGLETONS
            );

            let {logicProxy, storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;

            proxyLogic = logicProxy;
            proxyStorage = storageProxy;

            const jsonObject = fileObject[contractName] || {};

            jsonObject[network_id] = {
              'implementationAddressLogic': TwoKeyAffiliationCampaignsPaymentsHandler.address,
              'Proxy': logicProxy,
              'implementationAddressStorage': TwoKeyAffiliationCampaignsPaymentsHandlerStorage.address,
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
        await new Promise(async (resolve, reject) => {
          try {
            console.log('Setting initial params in TwoKeyAffiliationCampaignsPaymentsHandler contract on plasma network');
            let instance = await TwoKeyAffiliationCampaignsPaymentsHandler.at(proxyLogic);
            let txHash = instance.setInitialParams
            (
              TwoKeySingletonesRegistry.address,
              proxyStorage,
            );
            resolve(txHash);
          } catch (e) {
            reject(e);
          }
        })
      })
      .then(() => true);
  } else if(deployer.network.startsWith('private') || deployer.network.startsWith('plasma')) {
    console.log('Deploying private version of TwoKeyPlasmaAffiliationCampaignsPaymentsHandler contract');
    deployer.link(Call, TwoKeyPlasmaAffiliationCampaignsPaymentsHandler)
      .then(() => deployer.deploy(TwoKeyPlasmaAffiliationCampaignsPaymentsHandler))
      .then(() => TwoKeyPlasmaAffiliationCampaignsPaymentsHandler.deployed())
      .then(() => deployer.deploy(TwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage))
      .then(() => TwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage.deployed())
      .then(async () => {
        await new Promise(async (resolve, reject) => {
          try {
            let registry = await TwoKeyPlasmaSingletoneRegistry.at(TwoKeyPlasmaSingletoneRegistry.address);

            console.log('-----------------------------------------------------------------------------------');
            console.log('... Adding TwoKeyPlasmaAffiliationCampaignsPaymentsHandler to Proxy registry as valid implementation');

            let contractName = "TwoKeyPlasmaAffiliationCampaignsPaymentsHandler";
            let contractStorageName = "TwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage";

            await registry.addVersionDuringCreation(
              contractName,
              contractStorageName,
              TwoKeyPlasmaAffiliationCampaignsPaymentsHandler.address,
              TwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage.address,
              INITIAL_VERSION_OF_ALL_SINGLETONS
            );

            let {logs} = await registry.createProxy(
              contractName,
              contractStorageName,
              INITIAL_VERSION_OF_ALL_SINGLETONS
            );

            let {logicProxy, storageProxy} = logs.find(l => l.event === 'ProxiesDeployed').args;

            proxyLogic = logicProxy;
            proxyStorage = storageProxy;

            const jsonObject = fileObject[contractName] || {};

            jsonObject[network_id] = {
              'implementationAddressLogic': TwoKeyPlasmaAffiliationCampaignsPaymentsHandler.address,
              'Proxy': logicProxy,
              'implementationAddressStorage': TwoKeyPlasmaAffiliationCampaignsPaymentsHandlerStorage.address,
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
        await new Promise(async (resolve, reject) => {
          try {
            console.log('Setting initial params in TwoKeyPlasmaAffiliationCampaignsPaymentsHandler contract on plasma network');
            let instance = await TwoKeyPlasmaAffiliationCampaignsPaymentsHandler.at(proxyLogic);
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


