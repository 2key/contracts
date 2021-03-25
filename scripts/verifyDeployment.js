// Require Web3 Module
let Web3 = require('web3');

const constants = require('./constants');
const proxyContract = require('../build/contracts/Proxy.json');
const proxyAddresses = require('../build/proxyAddresses.json');
const singletonsRegistryPublic = require('../build/contracts/TwoKeySingletonesRegistry.json');
const singletonsRegistryPlasma = require('../build/contracts/TwoKeyPlasmaSingletoneRegistry.json');

const promisify = constants.promisify;

let rpcs = {};
let ids = {};
let issuesFound = {};

const getBranch = async () => {
    return await constants.getGitBranch();
};

const loadRpcsForBranch = async() => {
    let branch = await getBranch();
    rpcs["public"] = constants.rpcs[`${branch}-public`];
    rpcs["private"] = constants.rpcs[`${branch}-private`];
    ids["public"] = constants.ids[`${branch}-public`];
    ids["private"] = constants.ids[`${branch}-private`];
}


const loadContracts = () => {
    let plasmaContracts = [];
    let publicContracts = [];

    for (let contract in proxyAddresses) {
        if (contract.toString().includes('Plasma')) {
            plasmaContracts.push(contract.toString());
        } else {
            publicContracts.push(contract.toString());
        }
    }

    return ({
        plasmaContracts,
        publicContracts
    });
}

const loadAddressInBuild = (contractName,networkId) => {
    let build = require(`../build/contracts/${contractName}.json`);
    return build.networks[networkId].address;
}

const logLine = () => {
    console.log('-----------------------------------------------------------------------------------');
};

const loadSingletonRegistry = (web3, networkId) => {
    if(networkId === 1 || networkId === 3) {
        return web3.eth.contract(singletonsRegistryPublic.abi).at(singletonsRegistryPublic.networks[networkId].address);
    } else {
        return web3.eth.contract(singletonsRegistryPlasma.abi).at(singletonsRegistryPlasma.networks[networkId].address);
    }
}

const verifyCampaigns = async(campaigns, networkId, rpc) => {
    // Show web3 where it needs to look for the Ethereum node
    let web3 = new Web3(new Web3.providers.HttpProvider(rpc));

    // Load singleton registry contract
    let SingletonRegistry = loadSingletonRegistry(web3,networkId);

    console.log('\n Starting campaigns verification');
    logLine();

    for(let campaignType in campaigns) {

        console.log('Campaign type being verified: ', campaignType);
        let contracts = campaigns[campaignType];

        for(let i=0; i<contracts.length; i++) {
            let latestAddedVersion = await promisify(
                SingletonRegistry.getLatestAddedContractVersion, [contracts[i]]
            );

            let latestApprovedVersion = await promisify(
                SingletonRegistry.getLatestCampaignApprovedVersion, [campaignType]
            )

            if (latestAddedVersion === latestApprovedVersion) {
                console.log('|  Verification Status : ✅      |      Contract name: ', contracts[i]);
            } else {
                console.log('|  Verification Status : ❌      |      Contract name: ', contracts[i]);
                issuesFound[contracts[i]] = {
                    latestAddedVersion,
                    'latestApprovedVersion': latestApprovedVersion
                };
            }
        }
    }


    logLine();
}

const verifyDeployment = async(contracts, networkId, rpc) => {
    // Show web3 where it needs to look for the Ethereum node
    let web3 = new Web3(new Web3.providers.HttpProvider(rpc));

    // Load singleton registry contract
    let SingletonRegistry = loadSingletonRegistry(web3,networkId);

    // Load the ABI of proxy contracts
    let proxyAbi = proxyContract.abi;

    // Log the message
    console.log('\n Starting contracts verification');
    logLine();
    // Iterate through all contracts which are not plasma
    for(let i=0; i<contracts.length; i++) {
        let contract = contracts[i];
        // Get contract address
        let contractAddress = proxyAddresses[contract][networkId]["Proxy"];
        // Load proxy contract
        let ProxyContract = web3.eth.contract(proxyAbi).at(contractAddress);
        // Check implementation to which contract points
        let implementationOnContract = await promisify(ProxyContract.implementation,[]);

        let latestAddedVersion = await promisify(
            SingletonRegistry.getLatestAddedContractVersion,[contract.toString()]
        );

        let latestAddedImplementation = await promisify(
            SingletonRegistry.getVersion,[contract.toString(),latestAddedVersion]
        );

        let addressInBuild = loadAddressInBuild(contract,networkId);
        if(latestAddedImplementation === implementationOnContract && implementationOnContract === addressInBuild) {
            console.log('|  Verification Status : ✅      |      Contract name: ', contract);
        } else {
            console.log('|  Verification Status : ❌      |      Contract name: ', contract);
            issuesFound[contract] = {
                implementationOnContract,
                latestAddedImplementation,
                latestAddedVersion,
                addressInBuild
            };
        }
    }

    logLine();
}


const verify = async() => {
    // Load the rpcs for this branch
    await loadRpcsForBranch();
    // Load contracts
    let contracts = loadContracts();
    // Verify deployment for public
    await verifyDeployment(
        contracts.publicContracts,
        ids["public"],
        rpcs["public"],
    );

    await verifyCampaigns(
        constants.campaigns["public"],
        ids["public"],
        rpcs["public"],
    );

    // Verify deployment for plasma
    await verifyDeployment(
        contracts.plasmaContracts,
        ids["private"],
        rpcs["private"]
    );

    await verifyCampaigns(
        constants.campaigns["private"],
        ids["private"],
        rpcs["private"],
    );

    if(Object.keys(issuesFound).length > 0) {
        for (let key in issuesFound) {
            console.log('❌ Contract with problem: ', key);
            console.log('Details:\n', JSON.stringify(issuesFound[key], 0, 3));
            console.log('Solution: Upgrade contract to latest added version: ', issuesFound[key]["latestAddedVersion"]);
            logLine();
        }
    }
}

verify();

