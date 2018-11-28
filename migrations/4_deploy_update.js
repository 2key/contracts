const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegLogic = artifacts.require('TwoKeyRegLogic');
const Registry = artifacts.require('Registry');
const Proxy = artifacts.require('UpgradeabilityProxy');
const json = require('../2key-protocol/proxyAddresses.json');

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
        console.log('Arugment is found');
        deployer.deploy(TwoKeyRegLogic)
            .then(() => TwoKeyRegLogic.deployed()
            .then(async(twoKeyRegLogic) => {
                await new Promise(async(resolve,reject) => {
                        try {
                            console.log('Setting initial parameters in TwoKeyRegLogic...');
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
            .then(() => Registry.deployed()
            .then(async (registry) => {
                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('Adding new version to the registry contract...');
                        let txHash = await registry.addVersion("1.2",TwoKeyRegLogic.address);
                        console.log('Upgrading proxy to new version');
                        txHash = await Proxy.at(json.Proxy).upgradeTo("1.2");
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