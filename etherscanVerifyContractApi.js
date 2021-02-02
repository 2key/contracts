const fetch = require('isomorphic-fetch');
const fs = require('fs');
const path = require('path');
const { runProcess } = require('./helpers');
const proxyFile = path.join(__dirname, './build/proxyAddresses.json');
const FormData = require('form-data');

require('dotenv').config({ path: path.resolve(process.cwd(), './.env.private')});

const contractToLibrary = {
  'TwoKeyUpgradableExchange' : ['PriceDiscovery'],
  'TwoKeyRegistry' : ['Call'],
  'TwoKeySignatureValidator' : ['Call'],
  'TwoKeyParticipationMiningPool' : ['Call']
}

/**
 * Mock method to simulate async call
 *
 * @param val {any}
 * @param time {Number}
 * @return {Promise<any>}
 */

const wait = (time = 500, val = true) => new Promise((resolve) => {
  setTimeout(() => { resolve(val); }, time);
});


/**
 * Load all deployed proxies
 * @returns {{}}
 */
const loadAddressesAndNetworks = () => {
  // Open proxyAddresses file
  let fileObject = {};
  if (fs.existsSync(proxyFile)) {
    fileObject = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf8' }));
  }
  return fileObject;
};


/**
 * Load library address from build
 * @param libraryName
 * @param networkId
 * @returns {null|*}
 */
const loadLibraryAddress = (libraryName, networkId) => {
  const artifactFile = path.join(__dirname, `./build/contracts/${libraryName}.json`);
  let artifact = {}
  if(fs.existsSync(artifactFile)) {
    artifact = JSON.parse(fs.readFileSync(artifactFile));
    return artifact['networks'][networkId].address;
  } else {
    console.log('Library does not exist.');
    return null;
  }
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


/**
 * Function to run contract verification
 * @param contractName
 * @param networkId
 * @returns {Promise<string>}
 */
const verifyContract = async(contractName, networkId) => {
  let contracts = loadAddressesAndNetworks();

  if(!contracts[contractName]) {
    return 'Contract does not have any address. Probably it is abstract.'
  } else if(!contracts[contractName][networkId]) {
    return 'Contract is not deployed to selected network.'
  }

  let contractAddress = contracts[contractName][networkId].implementationAddressLogic;
  let etherscanUrl = `https://etherscan.io/address/${contractAddress}#code`;
  let contract = fs.readFileSync(__dirname + `/flattenedContracts/${contractName}Flattened.sol`,'utf8');


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

  // In case contract has libraries
  if(contractToLibrary[contractName]) {
    let libraries = contractToLibrary[contractName];
    for(let i=0; i<libraries.length; i++) {
      let libraryName = libraries[i];
      let libraryAddress = loadLibraryAddress(libraryName, networkId);

      form.append(`libraryname${i+1}`, libraryName);
      form.append(`libraryaddress${i+1}`, libraryAddress);
    }
  }

  await etherscanApiCall(form);
  console.log('Etherscan url: ', etherscanUrl);
}


/**
 * Function to retry calls until the response is given
 * @param guid
 * @returns {Promise<any>}
 */
const retryVerify = async (guid) => {
  let url = `https://api.etherscan.io/api?apikey=${process.env.ETHERSCAN_API_KEY}&guid=${guid}&module=contract&action=checkverifystatus`
  const resp = await fetch(
    url,
    {
      method: 'GET'
    },
  );
  if (!resp) {
    await wait(10000);
    return retryVerify(guid);
  }

  return resp.json();
};


/**
 *
 * @param form
 * @returns {Promise<void>}
 */
const etherscanApiCall = async (form) => {
  const resp = await fetch(
    'http://api.etherscan.io/api',
    {
      method: 'POST',
      body: form
    }
  ).then((r) => {
    return r.json();
  });


  if (resp.status !== '0') {
    let guid = resp.result;
    console.log('✅ Contract submitted for verification --> Receipt:',guid);
    await wait(10000);
    const resp1 = await retryVerify(guid);
    console.log('Verification status: ', resp1);
  }
  else if (resp.status === '0' && resp.result === 'Contract source code already verified') {
    console.log(`✅ This contract is already verified`)
  }
  else {
    console.log('❌ There was an issue with verification request.');
    console.log(resp);
  }
}

/**
 *
 * @returns {Promise<void>}
 */
async function main() {
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
      let contractName = process.argv[3].toString();
      let networkId = process.argv[4].toString();
      await verifyContract(contractName, networkId);
      process.exit(0);
      break;
    }
    case '--verifyAllSingletons' : {
      let contracts = fs.readdirSync(`contracts/2key/singleton-contracts`);
      contracts = contracts.map(contractName => contractName.substring(0, contractName.indexOf('.sol')));
      const networkId = process.argv[3].toString();
      for(const contract of contracts) {
        await verifyContract(contract, networkId);
      }
      process.exit(0);
      break;
    }
    default:
      console.log('Bye');
      break;
  }
}

main().catch((e) => {
  console.log(e);
  process.exit(1);
});
