const fs = require('fs');
const path = './build/contracts/';
const sha256 = require('js-sha256');
const rhd = require('node-humanhash');

const singletones = [
    "TwoKeyAdmin",
    "TwoKeyEconomy",
    "TwoKeyUpgradableExchange",
    "TwoKeyEventSource",
    "TwoKeyReg",
    "TwoKeyPlasmaEvents"
];

const nonSingletones = [
    "TwoKeyConversionHandler",
    "ERC20TokenMock",
    "TwoKeyAcquisitionCampaignERC20",
];

// If dev-local 8086
// If rinkeby-infura 4

let networkId = "3";
const plasmaId = "17";

// Iterate through build file and get all singleton contracts name and address
// Iterate through build file and get all names and bytecodes
// Go through all bytecodes and generate hash

let singletoneAddresses = [];
let nonSingletoneBytecodes = [];

let singletonesDict = {};
let nonSingletonesDict = {};

/// Function to read all singletone files and write them to dict
function readSingletones() {
    for(let i=0; i<singletones.length; i++) {
        let file = path + singletones[i] + ".json";
        let jsonFile = require(file);
        if(singletones[i] == 'TwoKeyPlasmaEvents') {
            singletonesDict[singletones[i]] = jsonFile.networks[plasmaId]["address"];
            singletoneAddresses.push(jsonFile.networks[plasmaId]["address"]);

        } else {
            singletonesDict[singletones[i]] = jsonFile.networks[networkId]["address"];
            singletoneAddresses.push(jsonFile.networks[networkId]["address"]);
        };
    }
}

function readNonSingletones() {
    for(let i=0; i<nonSingletones.length; i++) {
        let file = path + nonSingletones[i] + ".json";
        let jsonFile = require(file);
        nonSingletonesDict[nonSingletones[i]] = {
            "bytecode" : jsonFile.bytecode,
            "address" : jsonFile.networks[networkId]["address"]
        };
        nonSingletoneBytecodes.push(jsonFile.bytecode);
    }
}

function calculateSingletoneAddressesHash() {
    let merged = "";
    for(let i=0; i<singletoneAddresses.length; i++) {
        merged = merged + singletoneAddresses[i];
    }
    let hashSingletoneAddresses = sha256(merged);
    return hashSingletoneAddresses;
}

function calculateNonSingletoneHash() {
    let merged = "";
    for(let i=0; i<nonSingletoneBytecodes.length; i++) {
        merged = merged + nonSingletoneBytecodes[i];
    }
    let hashNonSingletoneBytecodes = sha256(merged);
    return hashNonSingletoneBytecodes;
}

function writeToFile() {
    readSingletones();
    readNonSingletones();
    let singletoneHash = calculateSingletoneAddressesHash();
    let nonSingletoneHash = calculateNonSingletoneHash();
    let humanHashSingletone = rhd.humanizeDigest(singletoneHash,4);
    let humanHashNonSingletone = rhd.humanizeDigest(nonSingletoneHash,4);

    let dict = {};

    dict["networkId"] = networkId;
    dict["hash"] = {
        "singletoneHash" : singletoneHash,
        "nonSingletoneHash" : nonSingletoneHash,

        "humanHash" : {
            "singletoneHuman" : humanHashSingletone,
            "nonSingletoneHuman" : humanHashNonSingletone,
        }
    };

    dict["singletones"] = singletonesDict;
    dict["nonSingletones"] = nonSingletonesDict;

    let dictstring = JSON.stringify(dict);
    fs.writeFileSync("./2key-protocol/contracts_version.json", dictstring);
}

function wrapper(idOfNetwork) {
    networkId = idOfNetwork;
    readSingletones();
    readNonSingletones();
    calculateSingletoneAddressesHash();
    calculateNonSingletoneHash();
    writeToFile();
}
function main() {
    const command = process.argv[2];
    if(command != '--network') {
        console.log('Wrong arguments \nTry running with \'--network {network_name}\'');
        console.log('Network name can be: ropsten, rinkeby, dev-local');
        return;
    }
    const network = process.argv[3];

    if(network == 'ropsten') {
        networkId = "3";
    } else if(network == 'rinkeby') {
        networkId = "4";
    } else if(network == 'dev-local') {
        networkId = "8086";
    }
    writeToFile();
    console.log("Done");
}

main();

module.exports = {
    wrapper,
}