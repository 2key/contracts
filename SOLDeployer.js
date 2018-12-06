const fs = require('fs');
const path = require('path');
const util = require('util');
const tar = require('tar');
const rimraf = require('rimraf');
const sha256 = require('js-sha256');
const rhd = require('node-humanhash');


// const compressor = require('node-minify');
const simpleGit = require('simple-git/promise');
const childProcess = require('child_process');
const moment = require('moment');
const ledgerProvider = require('./LedgerProvider');
const whitelist = require('./ContractDeploymentWhiteList.json');

const readdir = util.promisify(fs.readdir);
const buildPath = path.join(__dirname, 'build', 'contracts');
const buildBackupPath = path.join(__dirname, 'build', 'contracts.bak');
const twoKeyProtocolDir = path.join(__dirname, '2key-protocol', 'src');
const twoKeyProtocolDist = path.join(__dirname, '2key-protocol', 'dist');
const buildArchPath = path.join(twoKeyProtocolDir, 'contracts.tar.gz');
const twoKeyProtocolLibDir = path.join(__dirname, '2key-protocol', 'dist');

const deploymentHistoryPath = path.join(__dirname, 'history.json');

let deployment = false;

const contractsGit = simpleGit();
const twoKeyProtocolLibGit = simpleGit(twoKeyProtocolLibDir);
const versioning = require('./generateContractsVersioning');
/**
 *
 * @type {{}}
 */
let maintainerAddress = {};
maintainerAddress['rinkeby'] = '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f';
maintainerAddress['ropsten'] = '0x99663fdaf6d3e983333fb856b5b9c54aa5f27b2f';
maintainerAddress['local'] = '0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7';

async function handleExit(p) {
  console.log(p);
  if (p !== 0 && (process.argv[2] !== '--migrate' && process.argv[2] !== '--update' && process.argv[2] !== '--test' && process.argv[2] !== '--ledger')) {
    await contractsGit.reset('hard');
    await twoKeyProtocolLibGit.reset('hard');
  }
  process.exit();
}

process.on('exit', handleExit);
process.on('SIGINT', handleExit);
process.on('SIGUSR1', handleExit);
process.on('SIGUSR2', handleExit);
process.on('uncaughtException', handleExit);


const getCurrentDeployedAddresses = () => new Promise((resolve) => {
  const contracts = {};
  if (fs.existsSync(buildPath)) {
    readdir(buildPath).then((files) => {
      const l = files.length;
      for (let i = 0; i < l; i += 1) {
        const {
          networks, contractName, bytecode, abi
        } = JSON.parse(fs.readFileSync(path.join(buildPath, files[i])));
        if (networks && Object.keys(networks).length) {
          contracts[contractName] = networks;
        }
      }
      resolve(contracts);
    });
  } else {
    resolve(contracts);
  }
});

const rmDir = (dir) => new Promise((resolve) => {
  rimraf(dir, () => {
    resolve();
  })
});


const archiveBuild = () => new Promise(async (resolve, reject) => {
  try {
    if (fs.existsSync(buildPath)) {
      console.log('Archiving current artifacts to', buildArchPath);
      tar.c({
        gzip: true, sync: true, cwd: path.join(__dirname, 'build')
      }, ['contracts'])
        .pipe(fs.createWriteStream(buildArchPath));


      await rmDir(buildPath);
      if (fs.existsSync(buildBackupPath)) {
        console.log('Restoring artifacts from backup', buildBackupPath);
        fs.renameSync(buildBackupPath, buildPath);
      }
    }
    resolve();
  } catch (err) {
    reject(err);
  }
});

const restoreFromArchive = () => new Promise(async (resolve, reject) => {
  try {
    if (fs.existsSync(buildPath)) {
      console.log('Backup current artifacts to', buildBackupPath);
      if (fs.existsSync(buildBackupPath)) {
        await rmDir(buildBackupPath);
      }
      fs.renameSync(buildPath, buildBackupPath);
    }
    if (fs.existsSync(buildArchPath)) {
      console.log('Excracting', buildArchPath)
      tar.x({file: buildArchPath, gzip: true, sync: true, cwd: path.join(__dirname, 'build')});
    }
    resolve()
  } catch (e) {
    reject(e);
  }
});

const generateSOLInterface = () => new Promise((resolve, reject) => {
  console.log('Generating abi');
  if (fs.existsSync(buildPath)) {
    let contracts = {};
    const proxyFile = path.join(buildPath, 'proxyAddresses.json');
    let json = {};
    let hashMap = {};
    let data = {};
    let proxyAddresses = {};
    if (fs.existsSync(proxyFile)) {
      proxyAddresses = JSON.parse(fs.readFileSync(proxyFile, { encoding: 'utf-8' }));
    }
    readdir(buildPath).then((files) => {
      try {
        files.forEach((file) => {
          const {
            networks, contractName, bytecode, abi
          } = JSON.parse(fs.readFileSync(path.join(buildPath, file), { encoding: 'utf-8' }));
          if (whitelist[contractName]) {
            // contracts[contractName] = whitelist[contractName].deployed
            //   ? { abi, networks } : { abi, networks, bytecode };
            const proxyNetworks = proxyAddresses[contractName] || {};
            const mergedNetworks = {};
            Object.keys(networks).forEach(key => {
              mergedNetworks[key] = { ...networks[key], ...proxyNetworks[key] };
            });
            contracts[contractName] = whitelist[contractName].singletone
              ? {networks: mergedNetworks, abi, name: contractName} : {bytecode, abi, name: contractName};
            json[contractName] = whitelist[contractName].singletone
              ? {networks: mergedNetworks, abi, name: contractName} : {bytecode, abi, name: contractName};

            let networkKeys = Object.keys(networks);

            networkKeys.forEach((key) => {
                if (Array.isArray(data[key.toString()])) {
                    data[key.toString()].push({
                        contract : contractName,
                        address : networks[key].address});
                } else {
                    data[key.toString()] = [{
                        contract : contractName,
                        address : networks[key].address}];
                }
            });
          }
        });
        let keyHash = {}
        let keys = Object.keys(data);
        keys.forEach((key) => {
            let arr = data[key];
            let arrayOfAddresses = [];
            arr.forEach((element) => {
                arrayOfAddresses.push(element.address);
            });
            let mergedString = [];
            arrayOfAddresses.forEach((address) => {
                mergedString = mergedString + address.toString();
            });

            let hash = sha256(mergedString);
            keyHash[key] =
                {
                    hash: hash,
                    humanHash: rhd.humanizeDigest(hash,8)
                };
        });
        let obj = {};
        obj['NetworkHashes'] = keyHash;

        let obj1 = {};
        obj1['Maintainers'] = maintainerAddress;
        contracts = Object.assign(obj, contracts);
        contracts = Object.assign(obj1, contracts);
        console.log('Writing contracts.ts...');
        fs.writeFileSync(path.join(twoKeyProtocolDir, 'contracts.ts'), `export default ${util.inspect(contracts, {depth: 10})}`);
        if (deployment) {
            json = Object.assign(obj,json);
            json = Object.assign(obj1,json);
            fs.writeFileSync(path.join(twoKeyProtocolDir, 'contracts_deployed.json'), JSON.stringify(json, null, 2));
            console.log('Writing contracts_deployed.json...');
            fs.copyFileSync(path.join(twoKeyProtocolDir, 'contracts_deployed.json'),path.join(twoKeyProtocolDist,'contracts_deployed.json'));
            console.log('Copying this to 2key-protcol/dist...');
        }
        console.log('Done');
        resolve();
      } catch (err) {
        reject(err);
      }
    });
  }
});

const runProcess = (app, args) => new Promise((resolve, reject) => {
  console.log('Run process', app, args && args.join(' '));
  const proc = childProcess.spawn(app, args, {stdio: [process.stdin, process.stdout, process.stderr]});
  proc.on('close', async (code) => {
    console.log('process exit with code', code);
    if (code === 0) {
      resolve(code);
    } else {
      reject(code);
    }
  });
});

async function deploy() {
  try {
    deployment = true;
    await contractsGit.fetch();
    await contractsGit.submoduleUpdate();
    let contractsStatus = await contractsGit.status();
    let twoKeyProtocolStatus = await twoKeyProtocolLibGit.status();
    if (twoKeyProtocolStatus.current !== contractsStatus.current) {
      const twoKeyProtocolBranches = await twoKeyProtocolLibGit.branch();
      if (twoKeyProtocolBranches.all.find(item => item.includes(contractsStatus.current))) {
        await twoKeyProtocolLibGit.checkout(contractsStatus.current);
      } else {
        await twoKeyProtocolLibGit.checkoutLocalBranch(contractsStatus.current);
      }
    }
    await contractsGit.submoduleUpdate();
    await twoKeyProtocolLibGit.reset('hard');
    twoKeyProtocolStatus = await twoKeyProtocolLibGit.status();
    const localChanges = contractsStatus.files
      // .filter(item => !(item.path.includes('2key-protocol-npm')
      .filter(item => !(item.path.includes('dist') || item.path.includes('contracts.ts') || item.path.includes('contracts_deployed.json')
        || (process.env.NODE_ENV === 'development' && item.path.includes(process.argv[1].split('/').pop()))));
    if (contractsStatus.behind || localChanges.length) {
      console.log('You have unsynced changes!', localChanges);
      process.exit(1);
    }
    console.log(process.argv);
    const local = process.argv[2].includes('local');
    if (!local && !process.env.SKIP_TEST) {
      await test();
    }

    // TODO: Add build/contracts backup
    await restoreFromArchive();

    const networks = process.argv[2].split(',');
    const network = networks.join('/');
    const now = moment();
    const commit = `SOL Deployed to ${network} ${now.format('lll')}`;
    const tag = `${network}-${now.format('YYYYMMDDHHmmss')}`;

    const deployedHistory = fs.existsSync(deploymentHistoryPath)
      ? JSON.parse(fs.readFileSync(deploymentHistoryPath)) : {};
    const artifacts = await getCurrentDeployedAddresses();
    if (Object.keys(artifacts).length) {
      if (!Object.keys(deployedHistory).length) {
        deployedHistory.initial = {
          contracts: artifacts
        };
      }
    }
    const l = networks.length;
    // Object.keys(whitelist).forEach(key => {
    //   if (whitelist[key].singletone) {
    //     fs.unlinkSync(path.join(buildPath, `${key}.json`));
    //   }
    // });
    // await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['compile', '--all']);
    for (let i = 0; i < l; i += 1) {
      /* eslint-disable no-await-in-loop */
      await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--network', networks[i]].concat(process.argv.slice(3)));
      /* eslint-enable no-await-in-loop */
    }
    console.log(commit);
    const sessionDeployedContracts = await getCurrentDeployedAddresses();
    const lastDeployed = Object.keys(deployedHistory).filter(key => key !== 'initial').sort((a, b) => {
      if (a > b) {
        return 1;
      }
      if (b > a) {
        return -1;
      }
      return 0;
    }).pop();
    const deployedUpdates = {
      contracts: {}
    };
    Object.keys(sessionDeployedContracts).forEach((contract) => {
      if (!lastDeployed || !lastDeployed[contract]
        || !Object.keys(lastDeployed[contract].networks).length) {
        deployedUpdates.contracts[contract] = {...sessionDeployedContracts[contract]};
      } else if (lastDeployed[contract] && Object.keys(lastDeployed[contract].networks).length) {
        Object.keys(lastDeployed[contract].networks).forEach((net) => {
          if (sessionDeployedContracts[contract].networks
            && sessionDeployedContracts[contract].networks[net]
            && sessionDeployedContracts[contract].networks[net].address
            && lastDeployed[contract].networks[net].address
            !== sessionDeployedContracts[contract].networks[net].address) {
            // deployUpdates.date = now.format();
            // deployUpdates.networks = networks;
            deployedUpdates.contracts[contract] = {
              ...sessionDeployedContracts[contract],
              networks: {
                ...deployedUpdates.contracts[contract].networks,
                [net]: sessionDeployedContracts[contract].networks[net]
              }
            };
          }
        });
      }
    });
    if (Object.keys(deployedUpdates.contracts).length) {
      deployedUpdates.data = now.format();
      deployedUpdates.networks = networks;
      deployedHistory[tag] = deployedUpdates;
      fs.writeFileSync(deploymentHistoryPath, JSON.stringify(deployedHistory, null, 2));
    }
    await generateSOLInterface();
    // await runProcess(path.join(__dirname, 'node_modules/.bin/typechain'), ['--force', '--outDir', path.join(twoKeyProtocolDir, 'contracts'), `${buildPath}/*.json`]);
    if (!local) {
      await runProcess(path.join(__dirname, 'node_modules/.bin/webpack'));
    }
    // TODO: Archive build
    await archiveBuild();

    contractsStatus = await contractsGit.status();
    twoKeyProtocolStatus = await twoKeyProtocolLibGit.status();
    console.log(commit, tag);
    await twoKeyProtocolLibGit.add(twoKeyProtocolStatus.files.map(item => item.path));
    await twoKeyProtocolLibGit.commit(commit);
    await contractsGit.add(contractsStatus.files.map(item => item.path));
    await contractsGit.commit(commit);
    await twoKeyProtocolLibGit.push('origin', contractsStatus.current);
    await contractsGit.push('origin', contractsStatus.current);

      /**
       * Npm patch & public
       * Get version of package
       * put the tag
       */
    if(!local) {
        process.chdir(twoKeyProtocolDist);
        await runProcess('npm',['version', 'patch']);
        var json = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        let npmVersionTag = json.version;
        console.log(npmVersionTag);
        process.chdir('../../');
        // await twoKeyProtocolLibGit.addTag(tag);
        await contractsGit.addTag('v'+npmVersionTag.toString());
        await twoKeyProtocolLibGit.pushTags('origin');
        await contractsGit.pushTags('origin');
        process.chdir(twoKeyProtocolDist);
        await runProcess('npm',['publish']);
    }
  } catch (e) {
    if (e.output) {
      e.output.forEach((buff) => {
        if (buff && buff.toString) {
          console.log(buff.toString('utf8'));
        }
      });
    } else {
      console.warn('Error', e);
    }
    await contractsGit.reset('hard');
  }
}

const test = () => new Promise(async (resolve, reject) => {
  // const testsPath = path.join(twoKeyProtocolDir, 'test');
  try {
    // await runProcess('node', ['-r', 'dotenv/config', './node_modules/.bin/mocha', '--exit', '--bail', '-r', 'ts-node/register', '2key-protocol/**/*.spec.ts']);
    await runProcess('node', ['-r', 'dotenv/config', './node_modules/.bin/mocha', '--exit', '--bail', '-r', 'ts-node/register', '2key-protocol/test/index.spec.ts']);
    resolve();
  } catch (err) {
    reject(err);
  }

  // if (fs.existsSync(testsPath)) {
  //   const files = (await readdir(testsPath)).filter(file => file.endsWith('.spec.ts'));
  //   const l = files.length;
  //   for (let i = 0; i < l; i += 1) {
  //     /* eslint-disable no-await-in-loop */
  //     await runProcess('node', ['-r', 'dotenv/config', './node_modules/.bin/mocha', '--exit', '--bail', '-r', 'ts-node/register', path.join(testsPath, files[i])]);
  //     /* eslint-enable no-await-in-loop */
  //   }
  // }
});

async function main() {
  const mode = process.argv[2];
  switch (mode) {
    case '--update':
      try {
        const networks = process.argv[3];
        //truffle migrate --network=dev-local --f 4 update
        fs.unlinkSync(path.join(buildPath, 'TwoKeyRegistry.json'));
        await runProcess('truffle',['migrate',`--network=${networks}`,'--f 4','update']);
        await generateSOLInterface();
        process.exit(0);
      } catch (err) {
        process.exit(1);
      }
      break;
    case '--migrate':
        try {
        const networks = process.argv[3].split(',');

        const l = networks.length;
        let flag = false;
        for (let i = 0; i < l; i += 1) {
          /* eslint-disable no-await-in-loop */
          await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--network', networks[i]].concat(process.argv.slice(4)));
          /* eslint-enable no-await-in-loop */
          if(networks[i] === 'public.test.k8s' || networks[i] === 'public.test.k8s-hdwallet' || networks[i] == 'ropsten') {
              flag = true;
          }
        }

        if(flag) {
            Console.log('Generating new contracts_version.json for 2key-protocol and config.json file for 2key-backend...');
            const pythonGenerate = spawn('python', ['./2key-backend/generate_config.py']);
            pythonGenerate.stdout.on('data', function(data) {
                console.log(data.toString());
            });
            versioning.wrapper(4);
        }
        // await runProcess(path.join(_dirname,'generateContractsVersioning.js'), ['--network'], networks[0]);
        //   console.log(path.join(_dirname,'generateContractsVersioning.js'), ['--network'], networks[0]);
        await generateSOLInterface();
        // await runProcess(path.join(__dirname, 'node_modules/.bin/typechain'), ['--force', '--outDir', path.join(twoKeyProtocolDir, 'contracts'), `${buildPath}/*.json`]);
          process.exit(0);
      } catch (err) {
        process.exit(1);
      }
      break;
    case '--test':
      test();
      break;
    case '--generate':
      generateSOLInterface();
      break;

    case '--archive':
      archiveBuild();
      break;
    case '--extract':
      restoreFromArchive();
      break;
    case '--ledger':
      ledgerProvider('https://ropsten.infura.io/v3/71d39c30bc984e8a8a0d8adca84620ad', { networkId: 3 });
      break;
    default:
      deploy();
  }
}

main();
