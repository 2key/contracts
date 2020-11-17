
const TwoKeyAffiliationCampaignsPaymentsHandler = artifacts.require('TwoKeyAffiliationCampaignsPaymentsHandler');
const TwoKeyAffiliationCampaignsPaymentsHandlerStorage = artifacts.require('TwoKeyAffiliationCampaignsPaymentsHandlerStorage');

const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');

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

    deployer.deploy(TwoKeyAffiliationCampaignsPaymentsHandler)
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

            let txHash = await registry.addVersionDuringCreation(
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
  }
};


