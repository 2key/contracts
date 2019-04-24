const TwoKeyEconomy = artifacts.require('TwoKeyEconomy');
const TwoKeyUpgradableExchange = artifacts.require('TwoKeyUpgradableExchange');
const TwoKeyAdmin = artifacts.require('TwoKeyAdmin');
const EventSource = artifacts.require('TwoKeyEventSource');
const TwoKeyRegistry = artifacts.require('TwoKeyRegistry');
const TwoKeyCongress = artifacts.require('TwoKeyCongress');
const TwoKeyPlasmaEvents = artifacts.require('TwoKeyPlasmaEvents');
const TwoKeySingletonesRegistry = artifacts.require('TwoKeySingletonesRegistry');
const TwoKeyExchangeRateContract = artifacts.require('TwoKeyExchangeRateContract');
const TwoKeyPlasmaSingletoneRegistry = artifacts.require('TwoKeyPlasmaSingletoneRegistry');
const TwoKeyBaseReputationRegistry = artifacts.require('TwoKeyBaseReputationRegistry');
const TwoKeyCommunityTokenPool = artifacts.require('TwoKeyCommunityTokenPool');
const TwoKeyDeepFreezeTokenPool = artifacts.require('TwoKeyDeepFreezeTokenPool');
const TwoKeyLongTermTokenPool = artifacts.require('TwoKeyLongTermTokenPool');
const TwoKeyCampaignValidator = artifacts.require('TwoKeyCampaignValidator');
const Call = artifacts.require('Call');
const IncentiveModels = artifacts.require('IncentiveModels');

const fs = require('fs');
const path = require('path');

const proxyFile = path.join(__dirname, '../build/contracts/proxyAddresses.json');

module.exports = function deploy(deployer) {
    const { network_id } = deployer;
    /**
     * Read the proxy file into fileObject
     * @type {{}}
     */
    let fileObject = {};
    if (fs.existsSync(proxyFile)) {
        fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
    }

    /**
     * Define proxyAddress variables for the contracts
     */
    let proxyAddressTwoKeyRegistry;
    let proxyAddressTwoKeyEventSource;
    let proxyAddressTwoKeyExchange;
    let proxyAddressTwoKeyAdmin;
    let proxyAddressTwoKeyUpgradableExchange;
    let proxyAddressTwoKeyBaseReputationRegistry;
    let proxyAddressTwoKeyCommunityTokenPool;
    let proxyAddressTwoKeyLongTermTokenPool;
    let proxyAddressTwoKeyDeepFreezeTokenPool;
    let proxyAddressTwoKeyCampaignValidator;

    /**
     * Define proxy address for plasma network
     */
    let proxyAddressTwoKeyPlasmaEvents;


    /**
     * Initial variables we need for contracts initial state
     */
    let initialCongressMembers = [
        '0x4216909456e770FFC737d987c273a0B8cE19C13e', // Eitan
        '0x5e2B2b278445AaA649a6b734B0945Bd9177F4F03', // Kiki
        '0x2230ed1a134737d305c0c962f0e75571cc02f585', //TieBrake
    ];

    /**
     * Initial names of the congress members, hexed values
     * @type {string[]}
     */
    let initialCongressMemberNames = [
        '0x456974616e000000000000000000000000000000000000000000000000000000', //Eitan hexed
        '0x4b696b6900000000000000000000000000000000000000000000000000000000', //Kiki hexed
        '0x5469654272616b65200000000000000000000000000000000000000000000000' // TieBrake hexed
    ];

    /**
     * Initial voting powers for congress members
     * @type {number[]}
     */
    let votingPowers = [1, 1, 1];



    let deployerAddress = '0x18e1d5ca01141E3a0834101574E5A1e94F0F8F6a';

    let maintainerAddresses = [];


    if(deployer.network.startsWith('public.test') || deployer.network.startsWith('plasma')) {
        /**
         * Network configuration for ropsten
         */
        maintainerAddresses = [
            '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f',
            '0x098a12404fd3f5a06cfb016eb7669b1c41419705',
            '0x1d55762a320e6826cf00c4f2121b7e53d23f6822',
            '0xbddd873d7945f67d1689fd7870649b81744badd6',
            '0xbf31911c8b9be1b5632fe52022e553fc7fe48a5d',
            '0x7a6ea86e08d20bc56885a30c379f6e12aafede26',
            '0xde205f05f5a50d5690959864dc3df4c1a6ac938c',
            '0xd128786ef2372cbd2629908226ddd0b712c540e7',
            '0x52e87d01b1c610424951281ebd1b00a3bcf3b681',
            '0x5be04cc75b52c6ae5bb4858d58fd57dd15f354e3',
            "0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f",
            "0x098a12404fd3f5a06cfb016eb7669b1c41419705",
            "0x1d55762a320e6826cf00c4f2121b7e53d23f6822",
            "0xbddd873d7945f67d1689fd7870649b81744badd6",
            "0xbf31911c8b9be1b5632fe52022e553fc7fe48a5d",
            "0x7a6ea86e08d20bc56885a30c379f6e12aafede26",
            "0xde205f05f5a50d5690959864dc3df4c1a6ac938c",
            "0xd128786ef2372cbd2629908226ddd0b712c540e7",
            "0x52e87d01b1c610424951281ebd1b00a3bcf3b681",
            "0x5be04cc75b52c6ae5bb4858d58fd57dd15f354e3",
            "0xa5f4e12a108593e067c7de0954b09929d580393f",
            "0x82dce68ed3e41217df2ba675d7f4ef47cde13ba0",
            "0x04dd7264042a3b1ddb72c60472a7a55a65ec536a",
            "0x4a81ee3b1e85cdb2784c671f9f7ba035480cbcf9",
            "0xaf6ffab83cab5a206ee4c2d360ebd30d2b656df8",
            "0xfbfaf205de3cd4d8e675977a3b423705d8bba4fc",
            "0x21ec81b671b6242113d4efc6c3070705a038fb80",
            "0x6bcbc29f342e08dac353b31784c0a7b9a41de55e",
            "0x80786d52e0591bb2d94547a44468d7755242bfee",
            "0x30ae76daa56363cec8021fb7cf7c4483f24f5891",
            "0xbf34656367112ddc8abac4a9a8073f1b149492bd",
            "0xd47e0be689d9b0aae9ffc8007b1e6777e03dfc5c",
            "0x5c5d9689e3fd90968cc0752aca14ff9d934067e8",
            "0x38e3bc742a762a1b4ccfcad2c4c69cfcc071fed1",
            "0x718bc8b735745ffcd68b450b958110ec835c5245",
            "0xd558c3a544738855767fa968f510c68592b3d8e4",
            "0x12b60119f22854a6dc512c2eede52a9841c5adac",
            "0xb7d5ea94e08df5afd0bedba96cdcb9baf35857e9",
            "0x79b929b9e9608a62edd1c3269072f5a0cab133d9",
            "0xc1eb44f46a5993e06aee92601a0470f9cb366816",
            "0x296c01ce11cfb3b4b39a048d76be3442f305e150",
            "0x4b303be91471e04c6e71ebf516a57950d2c65a3a",
            "0x3abd49cd2d8acdbc43f42ed74fa51b333992d9d9",
            "0x2f473f7e904024f4c7c191c7faeb08e6d3528030",
            "0x6d0f7e25275847d37ddea007a6d12cddf0c9c3d7",
            "0x1053b377900d7556b0a87f89b50ebd1bc5716f91",
            "0x774c9fde8dcf97af6f6466f9f89154618641c5a5",
            "0x28c72bb6bdc79e4e363e295c2c7b56bc40fd0274",
            "0x0e252a962210db8de606bd3db852a26d2f6cd0be",
            "0x77fff2a9631716f985a6e950e97a8c0ca12fc735",
            "0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7",
            "0xb3fa520368f2df7bed4df5185101f303f6c7decc"
        ];
    } else {
        /**
         * Network configuration for the dev-local testing purposes and plasma testing purposes
         */
        maintainerAddresses = [
            '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f',
            '0x098a12404fd3f5a06cfb016eb7669b1c41419705',
            '0x1d55762a320e6826cf00c4f2121b7e53d23f6822',
            '0xbddd873d7945f67d1689fd7870649b81744badd6',
            '0xbf31911c8b9be1b5632fe52022e553fc7fe48a5d',
            '0x7a6ea86e08d20bc56885a30c379f6e12aafede26',
            '0xde205f05f5a50d5690959864dc3df4c1a6ac938c',
            '0xd128786ef2372cbd2629908226ddd0b712c540e7',
            '0x52e87d01b1c610424951281ebd1b00a3bcf3b681',
            '0x5be04cc75b52c6ae5bb4858d58fd57dd15f354e3',
            '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7',
            "0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f",
            "0x098a12404fd3f5a06cfb016eb7669b1c41419705",
            "0x1d55762a320e6826cf00c4f2121b7e53d23f6822",
            "0xbddd873d7945f67d1689fd7870649b81744badd6",
            "0xbf31911c8b9be1b5632fe52022e553fc7fe48a5d",
            "0x7a6ea86e08d20bc56885a30c379f6e12aafede26",
            "0xde205f05f5a50d5690959864dc3df4c1a6ac938c",
            "0xd128786ef2372cbd2629908226ddd0b712c540e7",
            "0x52e87d01b1c610424951281ebd1b00a3bcf3b681",
            "0x5be04cc75b52c6ae5bb4858d58fd57dd15f354e3",
            "0xa5f4e12a108593e067c7de0954b09929d580393f",
            "0x82dce68ed3e41217df2ba675d7f4ef47cde13ba0",
            "0x04dd7264042a3b1ddb72c60472a7a55a65ec536a",
            "0x4a81ee3b1e85cdb2784c671f9f7ba035480cbcf9",
            "0xaf6ffab83cab5a206ee4c2d360ebd30d2b656df8",
            "0xfbfaf205de3cd4d8e675977a3b423705d8bba4fc",
            "0x21ec81b671b6242113d4efc6c3070705a038fb80",
            "0x6bcbc29f342e08dac353b31784c0a7b9a41de55e",
            "0x80786d52e0591bb2d94547a44468d7755242bfee",
            "0x30ae76daa56363cec8021fb7cf7c4483f24f5891",
            "0xbf34656367112ddc8abac4a9a8073f1b149492bd",
            "0xd47e0be689d9b0aae9ffc8007b1e6777e03dfc5c",
            "0x5c5d9689e3fd90968cc0752aca14ff9d934067e8",
            "0x38e3bc742a762a1b4ccfcad2c4c69cfcc071fed1",
            "0x718bc8b735745ffcd68b450b958110ec835c5245",
            "0xd558c3a544738855767fa968f510c68592b3d8e4",
            "0x12b60119f22854a6dc512c2eede52a9841c5adac",
            "0xb7d5ea94e08df5afd0bedba96cdcb9baf35857e9",
            "0x79b929b9e9608a62edd1c3269072f5a0cab133d9",
            "0xc1eb44f46a5993e06aee92601a0470f9cb366816",
            "0x296c01ce11cfb3b4b39a048d76be3442f305e150",
            "0x4b303be91471e04c6e71ebf516a57950d2c65a3a",
            "0x3abd49cd2d8acdbc43f42ed74fa51b333992d9d9",
            "0x2f473f7e904024f4c7c191c7faeb08e6d3528030",
            "0x6d0f7e25275847d37ddea007a6d12cddf0c9c3d7",
            "0x1053b377900d7556b0a87f89b50ebd1bc5716f91",
            "0x774c9fde8dcf97af6f6466f9f89154618641c5a5",
            "0x28c72bb6bdc79e4e363e295c2c7b56bc40fd0274",
            "0x0e252a962210db8de606bd3db852a26d2f6cd0be",
            "0x77fff2a9631716f985a6e950e97a8c0ca12fc735",
            "0xfab160d5bdebd8139f18b521cf18e876894ea44d",
            "0xb3fa520368f2df7bed4df5185101f303f6c7decc"
        ];

        initialCongressMembers = [
            '0xb3fa520368f2df7bed4df5185101f303f6c7decc',
            '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7',
            '0xf3c7641096bc9dc50d94c572bb455e56efc85412'
        ];

        initialCongressMemberNames = [
            '0x456974616e000000000000000000000000000000000000000000000000000000', //Eitan hexed
            '0x4b696b6900000000000000000000000000000000000000000000000000000000', //Kiki hexed
            '0x4b696b6900000000000000000000000000000000000000000000000000000000' // Kiki
        ];

        votingPowers = [1,1,1];
    }


    /**
     * Deployment process
     */
    deployer.deploy(Call);
    deployer.deploy(IncentiveModels);
    if (deployer.network.startsWith('dev') || deployer.network.startsWith('public.') || deployer.network.startsWith('rinkeby') || deployer.network.startsWith('ropsten')) {
        deployer.deploy(TwoKeyCongress, 24*60, initialCongressMembers, initialCongressMemberNames, votingPowers)
            .then(() => TwoKeyCongress.deployed())
            .then(() => deployer.deploy(TwoKeyCampaignValidator))
            .then(() => TwoKeyCampaignValidator.deployed())
            .then(() => deployer.deploy(TwoKeyAdmin))
            .then(() => TwoKeyAdmin.deployed())
            .then(() => deployer.deploy(TwoKeyExchangeRateContract))
            .then(() => TwoKeyExchangeRateContract.deployed())
            .then(() => deployer.deploy(EventSource))
            .then(() => deployer.link(Call, TwoKeyRegistry))
            .then(() => deployer.deploy(TwoKeyRegistry)
                .then(() => TwoKeyRegistry.deployed())
                .then(() => deployer.deploy(TwoKeyBaseReputationRegistry))
                .then(() => TwoKeyBaseReputationRegistry.deployed())
                .then(() => deployer.deploy(TwoKeyUpgradableExchange))
                .then(() => TwoKeyUpgradableExchange.deployed())
                .then(() => deployer.deploy(TwoKeyCommunityTokenPool))
                .then(() => TwoKeyCommunityTokenPool.deployed())
                .then(() => deployer.deploy(TwoKeyDeepFreezeTokenPool))
                .then(() => TwoKeyDeepFreezeTokenPool.deployed())
                .then(() => deployer.deploy(TwoKeyLongTermTokenPool))
                .then(() => TwoKeyLongTermTokenPool.deployed())
                .then(() => deployer.deploy(TwoKeySingletonesRegistry, maintainerAddresses, '0x0')) //adding empty admin address
                .then(() => TwoKeySingletonesRegistry.deployed().then(async (registry) => {
                    /**
                     * Here we will be adding all contracts to the Registry and create a Proxies for them
                     */
                    await new Promise(async (resolve, reject) => {
                        try {
                            console.log('... Adding TwoKeyRegistry to Proxy registry as valid implementation');
                            /**
                             * Adding TwoKeyRegistry to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                             */
                            let txHash = await registry.addVersion("TwoKeyRegistry", "1.0", TwoKeyRegistry.address);
                            let { logs } = await registry.createProxy("TwoKeyRegistry", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyRegistry is : ' + proxy);
                            console.log('Network ID', network_id);
                            const twoKeyReg = fileObject.TwoKeyRegistry || {};
                            twoKeyReg[network_id] = {
                                'address': TwoKeyRegistry.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                maintainer_address: maintainerAddresses,
                            };


                            fileObject['TwoKeyRegistry'] = twoKeyReg;
                            proxyAddressTwoKeyRegistry = proxy;
                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });

                    await new Promise(async (resolve, reject) => {
                        try {
                            console.log('... Adding TwoKeyCampaignValidator to Proxy registry as valid implementation');
                            /**
                             * Adding TwoKeyCampaignValidator to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                             */
                            let txHash = await registry.addVersion("TwoKeyCampaignValidator", "1.0", TwoKeyCampaignValidator.address);
                            let { logs } = await registry.createProxy("TwoKeyCampaignValidator", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyCampaignValidator is : ' + proxy);
                            const twoKeyValidator = fileObject.TwoKeyCampaignValidator || {};
                            twoKeyValidator[network_id] = {
                                'address': TwoKeyCampaignValidator.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                maintainer_address: maintainerAddresses,
                            };


                            fileObject['TwoKeyCampaignValidator'] = twoKeyValidator;
                            proxyAddressTwoKeyCampaignValidator = proxy;
                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });

                    await new Promise(async (resolve, reject) => {
                        try {
                            console.log('... Adding TwoKeyCommunityTokenPool to Proxy registry as valid implementation');
                            /**
                             * Adding TwoKeyCommunityTokenPool to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                             */
                            let txHash = await registry.addVersion("TwoKeyCommunityTokenPool", "1.0", TwoKeyCommunityTokenPool.address);
                            let { logs } = await registry.createProxy("TwoKeyCommunityTokenPool", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyCommunityTokenPool is : ' + proxy);
                            const twoKeyCommunityTokenPool = fileObject.TwoKeyCommunityTokenPool || {};
                            twoKeyCommunityTokenPool[network_id] = {
                                'address': TwoKeyCommunityTokenPool.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                maintainer_address: maintainerAddresses,
                            };


                            fileObject['TwoKeyCommunityTokenPool'] = twoKeyCommunityTokenPool;
                            proxyAddressTwoKeyCommunityTokenPool = proxy;
                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });

                    await new Promise(async (resolve, reject) => {
                        try {
                            console.log('... Adding TwoKeyLongTermTokenPool to Proxy registry as valid implementation');
                            /**
                             * Adding TwoKeyLongTermTokenPool to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                             */
                            let txHash = await registry.addVersion("TwoKeyLongTermTokenPool", "1.0", TwoKeyLongTermTokenPool.address);
                            let { logs } = await registry.createProxy("TwoKeyLongTermTokenPool", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyLongTermTokenPool is : ' + proxy);
                            const twoKeyLongTermTokenPool = fileObject.TwoKeyLongTermTokenPool || {};
                            twoKeyLongTermTokenPool[network_id] = {
                                'address': TwoKeyLongTermTokenPool.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                maintainer_address: maintainerAddresses,
                            };


                            fileObject['TwoKeyLongTermTokenPool'] = twoKeyLongTermTokenPool;
                            proxyAddressTwoKeyLongTermTokenPool = proxy;
                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });

                    await new Promise(async (resolve, reject) => {
                        try {
                            console.log('... Adding TwoKeyDeepFreezeTokenPool to Proxy registry as valid implementation');
                            /**
                             * Adding TwoKeyLongTermTokenPool to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                             */
                            let txHash = await registry.addVersion("TwoKeyDeepFreezeTokenPool", "1.0", TwoKeyDeepFreezeTokenPool.address);
                            let { logs } = await registry.createProxy("TwoKeyDeepFreezeTokenPool", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyDeepFreezeTokenPool is : ' + proxy);
                            const twoKeyDeepFreezeTokenPool = fileObject.TwoKeyDeepFreezeTokenPool || {};
                            twoKeyDeepFreezeTokenPool[network_id] = {
                                'address': TwoKeyDeepFreezeTokenPool.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                maintainer_address: maintainerAddresses,
                            };


                            fileObject['TwoKeyDeepFreezeTokenPool'] = twoKeyDeepFreezeTokenPool;
                            proxyAddressTwoKeyDeepFreezeTokenPool = proxy;
                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });





                    await new Promise(async (resolve, reject) => {
                        try {
                            console.log('... Adding TwoKeyBaseReputationRegistry to Proxy registry as valid implementation');
                            /**
                             * Adding TwoKeyBaseReputationRegistry to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                             */
                            let txHash = await registry.addVersion("TwoKeyBaseReputationRegistry", "1.0", TwoKeyBaseReputationRegistry.address);
                            let { logs } = await registry.createProxy("TwoKeyBaseReputationRegistry", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyBaseReputationRegistry is : ' + proxy);
                            const twoKeyBaseRepReg = fileObject.TwoKeyBaseReputationRegistry || {};
                            twoKeyBaseRepReg[network_id] = {
                                'address': TwoKeyBaseReputationRegistry.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                // maintainer_address: maintainerAddresses,
                            };

                            fileObject['TwoKeyBaseReputationRegistry'] = twoKeyBaseRepReg;
                            proxyAddressTwoKeyBaseReputationRegistry = proxy;
                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });

                    await new Promise(async (resolve, reject) => {
                        try {
                            console.log('... Adding EventSource to Proxy registry as valid implementation');
                            /**
                             * Adding EventSource to the registry, deploying 1st proxy for that 1.0 version of EventSource and setting initial params there
                             */
                            let txHash = await registry.addVersion("TwoKeyEventSource", "1.0", EventSource.address);
                            let { logs } = await registry.createProxy("TwoKeyEventSource", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the EventSource is : ' + proxy);

                            const twoKeyEventS = fileObject.TwoKeyEventSource || {};

                            twoKeyEventS[network_id] = {
                                'address': EventSource.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                maintainer_address: deployerAddress,
                            };
                            fileObject['TwoKeyEventSource'] = twoKeyEventS;
                            proxyAddressTwoKeyEventSource = proxy;
                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });

                    await new Promise(async (resolve,reject) => {
                        try {
                            console.log('... Adding TwoKeyExchangeRateContract to Proxy registry as valid implementation');
                            /**
                             * Adding EventSource to the registry, deploying 1st proxy for that 1.0 version of EventSource
                             */
                            let txHash = await registry.addVersion("TwoKeyExchangeRateContract", "1.0", TwoKeyExchangeRateContract.address);
                            let { logs } = await registry.createProxy("TwoKeyExchangeRateContract", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyExchangeRateContract is : ' + proxy);

                            const twoKeyExchangeRate = fileObject.TwoKeyExchange || {};

                            twoKeyExchangeRate[network_id] = {
                                'address': TwoKeyExchangeRateContract.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                maintainer_address: maintainerAddresses,
                            };
                            fileObject['TwoKeyExchangeRateContract'] = twoKeyExchangeRate;
                            proxyAddressTwoKeyExchange = proxy;

                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });

                    await new Promise(async(resolve,reject) => {
                        try {
                            console.log('... Adding TwoKeyAdmin contract to proxy registry as valid implementation');
                            /**
                             * Adding TwoKeyAdmin to the registry, deploying 1st proxy for that 1.0 version of TwoKeyAdmin
                             */
                            let txHash = await registry.addVersion("TwoKeyAdmin", "1.0", TwoKeyAdmin.address);
                            let { logs } = await registry.createProxy("TwoKeyAdmin", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyAdmin contract is : ' + proxy);


                            // txHash = await TwoKeyAdmin.at(proxy).transfer2KeyTokens(proxyAddressTwoKeyRegistry, 1000000000000000);
                            const twoKeyAdmin = fileObject.TwoKeyAdmin || {};
                            twoKeyAdmin[network_id] = {
                                'address': TwoKeyAdmin.address,
                                'Proxy': proxy,
                                'Version': "1.0",
                                maintainer_address: deployerAddress
                            };

                            fileObject['TwoKeyAdmin'] = twoKeyAdmin;
                            proxyAddressTwoKeyAdmin = proxy;

                            resolve(proxy);

                        } catch (e) {
                            reject(e);
                        }
                    });

                    await new Promise(async(resolve,reject) => {
                        try {
                            console.log('... Adding TwoKeyUpgradableExchange contract to proxy registry as valid implementation');
                            /**
                             * Adding TwoKeyUpgradableExchange to the registry, deploying 1st proxy for that 1.0 version of TwoKeyUpgradableExchange
                             */
                            let txHash = await registry.addVersion("TwoKeyUpgradableExchange", "1.0", TwoKeyUpgradableExchange.address);
                            let { logs } = await registry.createProxy("TwoKeyUpgradableExchange", "1.0");
                            let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                            console.log('Proxy address for the TwoKeyUpgradableExchange contract is : ' + proxy);

                            const twoKeyUpgradableExchange = fileObject.TwoKeyUpgradableExchange || {};
                            twoKeyUpgradableExchange[network_id] = {
                                'address' : TwoKeyUpgradableExchange.address,
                                'Proxy' : proxy,
                                'Version' : "1.0",
                                maintainer_address: deployerAddress
                            };

                            fileObject['TwoKeyUpgradableExchange'] = twoKeyUpgradableExchange;
                            proxyAddressTwoKeyUpgradableExchange = proxy;
                            fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                            resolve(proxy);
                        } catch (e) {
                            reject(e);
                        }
                    });
                }))
                .then(() => deployer.deploy(TwoKeyEconomy,proxyAddressTwoKeyAdmin, TwoKeySingletonesRegistry.address))
                .then(() => TwoKeyEconomy.deployed())
                .then(async () => {
                    /**
                     * Here we will add congress contract to the registry
                     */
                    await new Promise(async (resolve,reject) => {
                        try {

                            console.log('Adding non-upgradable contracts to the registry');
                            console.log('Adding TwoKeyCongress to the registry as non-upgradable contract');
                            let txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                                .addNonUpgradableContractToAddress('TwoKeyCongress', TwoKeyCongress.address);
                            resolve(txHash);
                        } catch (e) {
                            reject(e);
                        }
                    });
                    /**
                     * Here we will add economy contract to the registry
                     */
                    await new Promise(async (resolve,reject) => {
                        try {
                            console.log('Adding TwoKeyEconomy to the registry as non-upgradable contract');
                            let txHash = await TwoKeySingletonesRegistry.at(TwoKeySingletonesRegistry.address)
                                .addNonUpgradableContractToAddress('TwoKeyEconomy', TwoKeyEconomy.address);
                            resolve(txHash);
                        } catch (e) {
                            reject(e);
                        }
                    });
                    console.log('... Setting Initial params in all singletone proxy contracts');

                    await new Promise(async (resolve, reject) => {
                        try {
                            await TwoKeyUpgradableExchange.at(proxyAddressTwoKeyUpgradableExchange).setInitialParams
                            (
                                95,
                                proxyAddressTwoKeyAdmin,
                                TwoKeyEconomy.address,
                                proxyAddressTwoKeyExchange,
                                proxyAddressTwoKeyCampaignValidator,
                                maintainerAddresses,
                            );
                            console.log('...TwoKeyUpgradableExchange Set Params ');

                            await TwoKeyCommunityTokenPool.at(proxyAddressTwoKeyCommunityTokenPool).setInitialParams
                            (
                                proxyAddressTwoKeyAdmin,
                                TwoKeyEconomy.address,
                                maintainerAddresses,
                                proxyAddressTwoKeyRegistry
                            );
                            console.log('...TwoKeyCommunityTokenPool Set Params ');


                            await TwoKeyLongTermTokenPool.at(proxyAddressTwoKeyLongTermTokenPool).setInitialParams
                            (
                                proxyAddressTwoKeyAdmin,
                                TwoKeyEconomy.address,
                                maintainerAddresses,
                            );
                            console.log('...TwoKeyLongTermTokenPool Set Params ');


                            await TwoKeyDeepFreezeTokenPool.at(proxyAddressTwoKeyDeepFreezeTokenPool).setInitialParams
                            (
                                proxyAddressTwoKeyAdmin,
                                TwoKeyEconomy.address,
                                maintainerAddresses,
                                proxyAddressTwoKeyCommunityTokenPool
                            );
                            console.log('...TwoKeyDeepFreezeTokenPool Set Params ');


                            await TwoKeyCampaignValidator.at(proxyAddressTwoKeyCampaignValidator).setInitialParams
                            (
                                TwoKeySingletonesRegistry.address,
                                maintainerAddresses
                            );
                            console.log('...TwoKeyCampaignValidator Set Params ');


                            await EventSource.at(proxyAddressTwoKeyEventSource).setInitialParams
                            (
                                proxyAddressTwoKeyAdmin,
                                maintainerAddresses,
                                proxyAddressTwoKeyRegistry,
                                proxyAddressTwoKeyCampaignValidator
                            );
                            console.log('...EventSource Set Params ');


                            await TwoKeyBaseReputationRegistry.at(proxyAddressTwoKeyBaseReputationRegistry).setInitialParams
                            (
                                TwoKeySingletonesRegistry.address,
                                maintainerAddresses
                            );
                            console.log('...TwoKeyBaseReputationRegistry Set Params ');


                            await TwoKeyExchangeRateContract.at(proxyAddressTwoKeyExchange).setInitialParams
                            (

                                maintainerAddresses,
                                proxyAddressTwoKeyAdmin
                            );
                            console.log('...TwoKeyExchangeRateContract Set Params ');





                            await TwoKeyAdmin.at(proxyAddressTwoKeyAdmin).setInitialParams
                            (
                                TwoKeyCongress.address,
                                TwoKeyEconomy.address,
                                proxyAddressTwoKeyUpgradableExchange,
                                proxyAddressTwoKeyRegistry,
                                proxyAddressTwoKeyEventSource
                            );
                            console.log('...TwoKeyAdmin Set Params ');


                            let txHash = await TwoKeyRegistry.at(proxyAddressTwoKeyRegistry).setInitialParams
                            (
                                proxyAddressTwoKeyEventSource,
                                proxyAddressTwoKeyAdmin,
                                maintainerAddresses,
                            );
                            console.log('...TwoKeyRegistry Set Params ');

                            resolve(txHash);
                        } catch (e) {
                            reject(e);
                        }
                    });
                })
                .then(() => true)
                .catch((err) => {
                    console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
                }));
    } else if (deployer.network.startsWith('plasma') || deployer.network.startsWith('private')) {
        deployer.link(Call, TwoKeyPlasmaEvents);
        deployer.deploy(TwoKeyPlasmaEvents)
            .then(() => deployer.deploy(TwoKeyPlasmaSingletoneRegistry, [], '0x0')) //adding empty admin address
            .then(() => TwoKeyPlasmaSingletoneRegistry.deployed().then(async (registry) => {
                await new Promise(async(resolve,reject) => {
                    try {
                        console.log('... Adding TwoKeyPlasmaEvents to Plasma Proxy registry as valid implementation');
                        /**
                         * Adding TwoKeyPlasmaEvents to the registry, deploying 1st proxy for that 1.0 version and setting initial params there
                         */
                        let txHash = await registry.addVersion("TwoKeyPlasmaEvents", "1.0", TwoKeyPlasmaEvents.address);
                        let { logs } = await registry.createProxy("TwoKeyPlasmaEvents", "1.0");
                        let { proxy } = logs.find(l => l.event === 'ProxyCreated').args;
                        console.log('Proxy address for the TwoKeyPlasmaEvents is : ' + proxy);
                        const twoKeyPlasmaEvents = fileObject.TwoKeyPlasmaEvents || {};

                        twoKeyPlasmaEvents[network_id] = {
                            'address': TwoKeyPlasmaEvents.address,
                            'Proxy': proxy,
                            'Version': "1.0",
                            maintainer_address: maintainerAddresses,
                        };
                        console.log('TwoKeyPlasmaEvents', network_id);
                        fileObject['TwoKeyPlasmaEvents'] = twoKeyPlasmaEvents;
                        proxyAddressTwoKeyPlasmaEvents = proxy;
                        fs.writeFileSync(proxyFile, JSON.stringify(fileObject, null, 4));
                        resolve(proxy);
                    } catch (e) {
                        reject(e);
                    }
                })
            }))
            .then(async () => {
                await new Promise(async (resolve,reject) => {
                    try {
                        console.log('Setting initial params in plasma contract on plasma network');
                        let txHash = await TwoKeyPlasmaEvents.at(proxyAddressTwoKeyPlasmaEvents).setInitialParams
                        (
                            maintainerAddresses
                        );
                        resolve(txHash);
                    } catch (e) {
                        reject(e);
                    }
                })
            })
            .then(() => true)
            .catch((err) => {
                console.log('\x1b[31m', 'Error:', err.message, '\x1b[0m');
            });
    }
};
