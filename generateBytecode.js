const Web3 = require('web3');
const abi = require('ethereumjs-abi');

const web3 = new Web3();

function generateSelector(name) {
  return web3.sha3(name).substring(2, 10);
}

function generateBytecode(name, types, values) {
  const selector = generateSelector(name);
  const packedArgs = abi.rawEncode(types, values).toString('hex');
  return `0x${selector}${packedArgs}`;
}

function generateBytecodeForTokenTransfer(deployer, amount) {
  const tokenAmount = parseFloat(amount) * (10**18);
  return generateBytecode('transfer2KeyTokens(address,uint256)', ['address', 'uint256'], [deployer, tokenAmount]);
}

function generateBytecodeForUpgrading(name, version) {
  return generateBytecode('upgradeContract(string,string)', ['string', 'string'], [name, version]);
}



module.exports.generateBytecodeForTokenTransfer = generateBytecodeForTokenTransfer;
module.exports.generateBytecodeForUpgrading = generateBytecodeForUpgrading;


console.log(generateBytecodeForUpgrading("TwoKeyUpgradableExchange", "1.1"));
