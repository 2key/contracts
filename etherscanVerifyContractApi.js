const fetch = require('isomorphic-fetch');
const fs = require('fs');
const path = require('path');
const { runProcess } = require('./helpers');
const proxyFile = path.join(__dirname, './build/proxyAddresses.json');
const FormData = require('form-data');
require('dotenv').config({ path: path.resolve(process.cwd(), './.env.private')});

const loadAddressesAndNetworks = () => {
  //Open proxyAddresses file
  let fileObject = {};
  if (fs.existsSync(proxyFile)) {
    fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
  }
  return fileObject;
}

/**
 * By passing contract name and directory name (just parent folder)
 * @param directoryName
 * @param contractName
 * @returns {Promise<void>}
 */
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

/**
 * Fetch all contracts inside specific directory
 * @type {function(*): string[]}
 */
const fetchAllContracts = ((directoryName) => {
  let contracts = fs.readdirSync(`contracts/2key/${directoryName}`);
  return contracts.map(contractName => contractName.substring(0, contractName.indexOf('.sol')))
})


/**
 * Function to flatten all contracts in selected directory
 * @type {function(*=): Promise<void>}
 */
const flattenContracts = (async (directoryName) => {
  let contracts = fetchAllContracts(directoryName);
  for (const contract of contracts) {
    await flattenContract(directoryName, contract)
      .then(r => console.log('Contract flattened: ', contract));
  }
})


const buildVerificationForm = (async (contractName, contractAddress, libsUsedNames, libsUsedAddresses) => {
  // Get instance of flattened contract code
  let contract = fs.readFileSync(__dirname + `/flattenedContracts/${contractName}Flattened.sol','utf8`);

  // Build a new form
  let form = new FormData();

  form.append( 'apikey' , process.env.ETHERSCAN_API_KEY)
  form.append( 'module' , 'contract')
  form.append( 'action' , 'verifysourcecode')
  form.append( 'contractaddress' , contractAddress)
  form.append( 'sourceCode' , contract)
  form.append( 'codeformat', 'solidity-single-file' )
  form.append( 'contractname',contractName)
  form.append( 'compilerversion','v0.4.24+commit.e67f0147')
  form.append( 'optimizationUsed' , '0')
  form.append( 'runs',200)
  form.append( 'constructorArguements' , "")
  form.append('evmversion',"")

  // Append the libraries to form
  for(let i = 0; i < libsUsedNames.length; i++) {
    form.append(`libraryname${i+1}`, libsUsedNames[i]);
    form.append(`libraryaddress${i+1}`, libsUsedAddresses[i]);
  }
})


const apiCall = async (form) => {
  const resp = await fetch(
    'http://api.etherscan.io/api',
    {
      method: 'POST',
      body: form
    }
  ).then((r) => {
    return r.json();
  })
  console.log('Response is: ', resp);
}

async function main() {
  console.log(process.argv);
  const mode = process.argv[2];
  switch (mode) {
    case '--flattenAll': {
      const dirName = process.argv[3];
      await flattenContracts(dirName);
      process.exit(0);
      break;
    }

    case '--flattenOne': {
      const dirName = process.argv[3];
      const contractName = process.argv[4];
      await flattenContract(dirName, contractName);
      process.exit(0);
      break;
    }

    case '--verifyContract': {
      let contracts = loadAddressesAndNetworks();
      let contractName = process.argv[3].toString();
      let networkId = process.argv[4].toString();
      let contractAddress = contracts[contractName][networkId].implementationAddressLogic;
      let form = buildVerificationForm(contractName, contractAddress, [], []);
      await apiCall(form);
    }
  }
}



main().catch((e) => {
  console.log(e);
  process.exit(1);
});

