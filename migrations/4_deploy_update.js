const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegLogic = artifacts.require('TwoKeyRegLogic');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const Proxy = artifacts.require('UpgradeabilityProxy');
const json = require('../2key-protocol/src/proxyAddresses.json');
const fs = require('fs');
module.exports = function deploy(deployer) {
    console.log(process.argv);
    let found = false;
    process.argv.forEach((argument) => {
        if (argument == 'update') {
            found = true
        }
    });

    if(found) {
        /**
         * This script is going to be executed only if the argument in migration command is 'update'
         */
        let lastTwoKeyRegLogicAddress;
        console.log('Arugment is found');
        deployer.deploy(TwoKeyRegLogic)
            .then(() => TwoKeyRegLogic.deployed()
            .then(async(twoKeyRegLogic) => {
                await new Promise(async(resolve,reject) => {
                        try {
                            console.log('Setting initial parameters in TwoKeyRegLogic...');
                            lastTwoKeyRegLogicAddress = twoKeyRegLogic.address;
                            let txHash = await twoKeyRegLogic.setInitialParams(
                                EventSource.address,
                                TwoKeyAdmin.address,
                                (deployer.network.startsWith('rinkeby') || deployer.network.startsWith('public.')) ? '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f' : '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7')

                            resolve(txHash);
                        } catch (e) {
                            reject(e);
                        }
                    })
                })
            .then(() => TwoKeySingletonesRegistry.deployed()
            .then(async (registry) => {
                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding new version to the registry contract');

                        let v = parseInt(json.TwoKeyRegistryLogic.Version.substr(-1)) + 1;
                        json['TwoKeyRegLogic'].Version = json.TwoKeyRegistryLogic.Version.substr(0,json.TwoKeyRegistryLogic.Version.length-1) + v.toString();
                        console.log('New version : '+ json.TwoKeyRegistryLogic.Version);

                        let txHash = await registry.addVersion(json.TwoKeyRegistryLogic.Version,TwoKeyRegLogic.address);
                        console.log('... Upgrading proxy to new version');

                        txHash = await Proxy.at(json.TwoKeyRegistryLogic.Proxy).upgradeTo(json.TwoKeyRegistryLogic.Version);

                        json.TwoKeyRegistryLogic.address = lastTwoKeyRegLogicAddress;
                        fs.writeFileSync('./2key-protocol/src/proxyAddresses.json',JSON.stringify(json,null,4));
                        console.log('proxyAddresses.json file is updated with newest version of contract');

                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })))
    } else {
        console.log('Argument is not found');
    }
}