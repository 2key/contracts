const fs = require('fs');
const {
  runProcess
} = require('./helpers');


/**
 * Function to compute arguments for flattening a single contract
 * @type {function(*): string}
 */
const computeArgs = ((contractName) => {
  let args =
    `solidity_flattener --solc-path="solc --allow-paths $PWD/contracts/2key/ 2key=$PWD/contracts/2key" contracts/2key/singleton-contracts/${contractName}.sol --output $PWD/flattenedContracts/${contractName+"Flattened"}.sol`
  return args;
})


const fetchAllContracts = ((directoryName) => {
  let contracts = fs.readdirSync(`contracts/2key/${directoryName}`);
  return contracts.map(contractName => contractName.substring(0, contractName.indexOf('.sol')))
})


const flattenContract = async (directoryName, contractName) => {
  // Compute the path stuff
  let workingDirectory = process.cwd();
  let solcAllowPaths = `--solc-path="solc --allow-paths ${workingDirectory}/contracts/2key/ 2key=${workingDirectory}/contracts/2key"`
  let contractPath = `contracts/2key/${directoryName}/${contractName}.sol`;
  let outputPath = `${workingDirectory}/flattenedContracts/${contractName+"Flattened"}.sol`

  try {
    await runProcess('solidity_flattener', [solcAllowPaths,contractPath,'--output',outputPath])
  } catch (e) {
    console.log('Error caught during flattening.');
  }
}


const flattenContracts = (async (directoryName) => {
  let contracts = fetchAllContracts(directoryName);
  for (const contract of contracts) {
    await flattenContract(directoryName, contract)
      .then(r => console.log('Contract flattened: ', contract));
  }
})

flattenContracts('singleton-contracts')
