const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const Proxy = artifacts.require('UpgradeabilityProxy');
const fs = require('fs');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');


module.exports = function deploy(deployer) {
    let maintainerAddress = (deployer.network.startsWith('ropsten') || deployer.network.startsWith('rinkeby') || deployer.network.startsWith('public.')) ? '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f' : '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';
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
        let lastTwoKeyRegistryAddress;
        console.log('Arugment is found');
        deployer.deploy(TwoKeyRegistry)
            .then(() => TwoKeyRegistry.deployed()
            .then(async(twoKeyRegistryInstance) => {
                await new Promise(async(resolve,reject) => {
                        try {
                            console.log('Setting initial parameters in TwoKeyRegistry...');
                            lastTwoKeyRegistryAddress = twoKeyRegistryInstance.address;
                            let txHash = await twoKeyRegistryInstance.setInitialParams(
                                EventSource.address,
                                TwoKeyAdmin.address,
                                maintainerAddress);

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
                        let json = {};
                        if (fs.existsSync(proxyFile)) {
                            json = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf-8' }));
                        }

                        let v = parseInt(json.TwoKeyRegistry.Version.substr(-1)) + 1;
                        json['TwoKeyRegistry'].Version = json.TwoKeyRegistry.Version.substr(0,json.TwoKeyRegistry.Version.length-1) + v.toString();
                        console.log('New version : '+ json.TwoKeyRegistry.Version);

                        let txHash = await registry.addVersion("TwoKeyRegistry",json.TwoKeyRegistry.Version,TwoKeyRegistry.address);
                        console.log('... Upgrading proxy to new version');

                        txHash = await Proxy.at(json.TwoKeyRegistry.Proxy).upgradeTo("TwoKeyRegistry",json.TwoKeyRegistry.Version);

                        json.TwoKeyRegistry.address = lastTwoKeyRegistryAddress;
                        fs.writeFileSync(proxyFile, JSON.stringify(json, null, 4));
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