const fs = require('fs');
const path = require('path');
const util = require('util');
const tar = require('tar');
const rimraf = require('rimraf');
const sha256 = require('js-sha256');
const rhd = require('node-humanhash');
const IPFS = require('ipfs-http-client');
const LZString = require('lz-string');
const { networks: truffleNetworks } = require('./truffle');
const { TwoKeyVersionHandler } = require('./2key-protocol/src/versions');


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
const twoKeyProtocolLibDir = path.join(__dirname, '2key-protocol', 'dist');
const twoKeyProtocolSubmodulesDir = path.join(__dirname, '2key-protocol', 'dist', 'submodules');

const deploymentHistoryPath = path.join(__dirname, 'history{branch}.json');
const buildArchPath = path.join(twoKeyProtocolDir, 'contracts{branch}.tar.gz');
let deployment = false;
const deployedTo = {};

let contractsStatus;

const getBuildArchPath = () => {
  if(contractsStatus && contractsStatus.current) {
    return buildArchPath.replace('{branch}',`-${contractsStatus.current}`);
  }
  return buildArchPath;
};

const getDeploymentHistoryPath = () => {
    if(contractsStatus && contractsStatus.current) {
        return deploymentHistoryPath.replace('{branch}',`-${contractsStatus.current}`);
    }
    return deploymentHistoryPath;
};

const getContractsDeployedPath = () => {
    const result = path.join(twoKeyProtocolDir,'contracts_deployed{branch}.json');
    if(contractsStatus && contractsStatus.current) {
        return result.replace('{branch}',`-${contractsStatus.current}`);
    }
    return result;
};

const getContractsDeployedDistPath = () => {
    const result = path.join(twoKeyProtocolDist,'contracts_deployed{branch}.json');
    if(contractsStatus && contractsStatus.current) {
        return result.replace('{branch}',`-${contractsStatus.current}`);
    }
    return result;
};


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
  if (p !== 0
    && (process.argv[2] !== '--migrate'
    && process.argv[2] !== '--generate'
    && process.argv[2] !== '--extract'
    && process.argv[2] !== '--update'
    && process.argv[2] !== '--test'
    && process.argv[2] !== '--ledger'
    && process.argv[2] !== '--submodules'
  )) {
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
      console.log('Archiving current artifacts to', getBuildArchPath());
      tar.c({
        gzip: true, sync: true, cwd: path.join(__dirname, 'build')
      }, ['contracts'])
        .pipe(fs.createWriteStream(getBuildArchPath()));


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
    if (fs.existsSync(getBuildArchPath())) {
      console.log('Excracting', getBuildArchPath())
      tar.x({file: getBuildArchPath(), gzip: true, sync: true, cwd: path.join(__dirname, 'build')});
    }
    resolve()
  } catch (e) {
    reject(e);
  }
});

const generateSOLInterface = () => new Promise((resolve, reject) => {
  console.log('Generating abi', deployedTo);
  if (fs.existsSync(buildPath)) {
    let contracts = {
      'contracts': {},
    };
    const proxyFile = path.join(buildPath, 'proxyAddresses.json');
    let json = {};
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
            const whiteListedContract = whitelist[contractName];
            // contracts[contractName] = whitelist[contractName].deployed
            //   ? { abi, networks } : { abi, networks, bytecode };
            const proxyNetworks = proxyAddresses[contractName] || {};
            const mergedNetworks = {};
            Object.keys(networks).forEach(key => {
              mergedNetworks[key] = { ...networks[key], ...proxyNetworks[key] };
            });
            if (!contracts.contracts[whiteListedContract.file]) {
              contracts.contracts[whiteListedContract.file] = {};
            }
            contracts.contracts[whiteListedContract.file][contractName] = { abi, name: contractName };
            if (whiteListedContract.networks) {
              contracts.contracts[whiteListedContract.file][contractName].networks = mergedNetworks;
            }
            if (whiteListedContract.bytecode) {
              contracts.contracts[whiteListedContract.file][contractName].bytecode = bytecode;
            }
            /*
              whitelist[contractName].singleton
              ? {networks: mergedNetworks, abi, name: contractName} : {bytecode, abi, name: contractName};
            */
            json[contractName] = whitelist[contractName].singleton
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
        const nonSingletonsBytecodes = [];
        const singletonsBytecodes = [];
        Object.keys(contracts.contracts).forEach(submodule => {
          if (submodule !== 'singletons') {
            Object.values(contracts.contracts[submodule]).forEach(({ bytecode, abi }) => {
              nonSingletonsBytecodes.push(bytecode || JSON.stringify(abi));
            });
          } else {
            Object.values(contracts.contracts[submodule]).forEach(({ address, abi }) => {
              singletonsBytecodes.push(address || JSON.stringify(abi));
            });
          }
        });
        const nonSingletonsHash = sha256(nonSingletonsBytecodes.join(''));
        const singletonsHash = sha256(singletonsBytecodes.join(''));
        Object.keys(contracts.contracts).forEach(key => {
          contracts.contracts[key]['NonSingletonsHash'] = nonSingletonsHash;
          contracts.contracts[key]['SingletonsHash'] = singletonsHash;
        });
        /*
        let keyHash = {};
        // deployedTo
        Object.keys(data).forEach((key) => {
            let arr = data[key];
            let arrayOfAddresses = [];
            arr.forEach((element) => {
                arrayOfAddresses.push(element.address);
            });
            let mergedString = [];
            arrayOfAddresses.forEach((address) => {
              if(address) {
                  mergedString = mergedString + address.toString();
              }
            });

            let hash = sha256(mergedString);
            keyHash[key] =
                {
                    hash: hash,
                    humanHash: rhd.humanizeDigest(hash,8)
                };
            if (deployedTo[key.toString()]) {
              keyHash[key]['NonSingletonsHash'] = nonSingletonsHash;
            }
        });
        */
        let obj = {
          'NonSingletonsHash': nonSingletonsHash,
          'SingletonsHash': singletonsHash,
          // 'NetworkHashes': keyHash,
        };

        let obj1 = {};
        obj1['Maintainers'] = maintainerAddress;

        //Handle updating contracts_deployed-develop.json
        /*
        let existingFile = path.join(twoKeyProtocolDir, 'contracts_deployed-develop.json');
        let fileObject = {};
        if (fs.existsSync(existingFile)) {
            fileObject = JSON.parse(fs.readFileSync(existingFile, { encoding: 'utf8' }));
        }
        */
        /**
         * Handle network hashes
         */
        /*
        let networkHashes = fileObject.NetworkHashes;
        Object.keys(networkHashes).forEach((key) => {
          let hashPerNetwork = networkHashes[key];
          if(obj['NetworkHashes'][key]['hash']) {
            hashPerNetwork['hash'] = obj['NetworkHashes'][key]['hash'];
          }
          if(obj['NetworkHashes'][key]['humanHash']) {
            hashPerNetwork['humanHash'] = obj['NetworkHashes'][key]['humanHash'];
          }
          if(obj['NetworkHashes'][key]['NonSingletonsHash']) {
            hashPerNetwork['NonSingletonsHash'] = obj['NetworkHashes'][key]['NonSingletonsHash'];
          }
          networkHashes[key] = hashPerNetwork;
        });
        obj['NetworkHashes'] = networkHashes;
        */

        contracts.contracts.singletons = Object.assign(obj, contracts.contracts.singletons);
        contracts.contracts.singletons = Object.assign(obj1, contracts.contracts.singletons);
        console.log('Writing contracts for submodules...');
        if(!fs.existsSync(path.join(twoKeyProtocolDir, 'contracts'))) {
          fs.mkdirSync(path.join(twoKeyProtocolDir, 'contracts'));
        }
        Object.keys(contracts.contracts).forEach(file => {
          fs.writeFileSync(path.join(twoKeyProtocolDir, 'contracts', `${file}.ts`), `export default ${util.inspect(contracts.contracts[file], {depth: 10})}`)
        });
        // fs.writeFileSync(path.join(twoKeyProtocolDir, 'contracts.ts'), `export default ${util.inspect(contracts, {depth: 10})}`);
        json = Object.assign(obj,json);
        json = Object.assign(obj1,json);
        fs.writeFileSync(getContractsDeployedPath(), JSON.stringify(json, null, 2));
        console.log('Writing contracts_deployed-develop.json...');
        if (deployment) {
            fs.copyFileSync(getContractsDeployedPath(),getContractsDeployedDistPath());
            console.log('Copying this to 2key-protocol/dist...');
        }
        console.log('Done');
        resolve(contracts);
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

const runMigration3 = (network) => new Promise(async(resolve, reject) => {
  try {
    if (!process.env.SKIP_3MIGRATION) {
      await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--f', '3', '--network', network]);
      resolve(true);
    } else {
      resolve(true);
    }
  } catch (e) {
    reject(e);
  }
});

const ipfs = new IPFS('ipfs.infura.io', 5001, { protocol: 'https' });

const ipfsCat = (hash) => new Promise((resolve, reject) => {
  ipfs.cat(hash, (err, res) => {
    if (err) {
      reject(err);
    } else {
      resolve(res);
    }
  });
});

const ipfsAdd = (data) => new Promise((resolve, reject) => {
  ipfs.add(ipfs.types.Buffer.from(data), { pin: deployment }, (err, res) => {
    if (err) {
      reject(err);
    } else {
      resolve(res);
    }
  });
});

const updateIPFSHashes = async(contracts) => {
  const nonSingletonHash = contracts.contracts.singletons.NonSingletonsHash;
  console.log(nonSingletonHash);


  let versionsList = {};
  if (TwoKeyVersionHandler) {
    versionsList = JSON.parse((await ipfsCat(TwoKeyVersionHandler)).toString());
    console.log('VERSION LIST', versionsList);
  }
  versionsList[nonSingletonHash] = {};
  const files = (await readdir(twoKeyProtocolSubmodulesDir)).filter(file => file.endsWith('.js'));
  for (let i = 0, l = files.length; i < l; i++) {
    const js = fs.readFileSync(path.join(twoKeyProtocolSubmodulesDir, files[i]), { encoding: 'utf-8' });
    console.time('Compress');
    const compressedJS = LZString.compressToUTF16(js);
    console.timeEnd('Compress');
    console.log(files[i], (js.length / 1024).toFixed(3), (compressedJS.length / 1024).toFixed(3));
    console.time('Upload');
    const [{ hash }] = await ipfsAdd(compressedJS);
    console.timeEnd('Upload');
    versionsList[nonSingletonHash][files[i].replace('.js', '')] = hash;
  }
  console.log(versionsList);
  const [{ hash: newTwoKeyVersionHandler }] = await ipfsAdd(JSON.stringify(versionsList));
  fs.writeFileSync(path.join(twoKeyProtocolDir, 'versions.json'), JSON.stringify({ TwoKeyVersionHandler: newTwoKeyVersionHandler }, null, 4));
  console.log('TwoKeyVersionHandler', newTwoKeyVersionHandler);
};

const commitAndPushContractsFolder = async(commitMessage) => {
  const contractsStatus = await contractsGit.status();
  await contractsGit.add(contractsStatus.files.map(item => item.path));
  await contractsGit.commit(commitMessage);
  await contractsGit.push('origin', contractsStatus.current);
};

async function deploy() {
  try {
    deployment = true;
    await contractsGit.fetch();
    await contractsGit.submoduleUpdate();
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
      .filter(item => !(item.path.includes('dist') || item.path.includes('contracts.ts') || item.path.includes('contracts_deployed')
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

    const deployedHistory = fs.existsSync(getDeploymentHistoryPath())
      ? JSON.parse(fs.readFileSync(getDeploymentHistoryPath())) : {};
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
      deployedTo[truffleNetworks[networks[i]].network_id.toString()] = truffleNetworks[networks[i]].network_id;
      await runMigration3(networks[i]);
      /* eslint-enable no-await-in-loop */
    }
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
      fs.writeFileSync(getDeploymentHistoryPath(), JSON.stringify(deployedHistory, null, 2));
    }
    const contracts = await generateSOLInterface();
    await archiveBuild();
    await commitAndPushContractsFolder(`Contracts deployed to ${network} ${now.format('lll')}`);
    console.log('Changes commited');
    await restoreFromArchive();
    await buildSubmodules(contracts);
    if (!local) {
      await runProcess(path.join(__dirname, 'node_modules/.bin/webpack'));
    }
    await archiveBuild();
    contractsStatus = await contractsGit.status();
    twoKeyProtocolStatus = await twoKeyProtocolLibGit.status();
    console.log(commit, tag);

    await twoKeyProtocolLibGit.add(twoKeyProtocolStatus.files.map(item => item.path));
    await twoKeyProtocolLibGit.commit(commit);
    await commitAndPushContractsFolder(commit);
    await twoKeyProtocolLibGit.push('origin', contractsStatus.current);

      /**
       * Npm patch & public
       * Get version of package
       * put the tag
       */
    if(!local || process.env.FORCE_NPM) {
        process.chdir(twoKeyProtocolDist);
        if (process.env.NODE_ENV === 'production') {
          await runProcess('npm', ['version', 'patch']);
        } else {
          const { version } = JSON.parse(fs.readFileSync(path.join(twoKeyProtocolDist, 'package.json'), 'utf8'));
          console.log(version);
          const versionArray = version.split('-')[0].split('.');
          console.log(versionArray);
          const patch = parseInt(versionArray.pop(), 10) + 1;
          console.log(patch);
          versionArray.push(patch);
          const newVersion = `${versionArray.join('.')}-${contractsStatus.current}`;
          console.log(newVersion);
          await runProcess('npm', ['version', newVersion])
        }
        const json = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        let npmVersionTag = json.version;
        console.log(npmVersionTag);
        process.chdir('../../');
        // await twoKeyProtocolLibGit.addTagcd(tag);
        await contractsGit.addTag('v'+npmVersionTag.toString());
        await twoKeyProtocolLibGit.pushTags('origin');
        await contractsGit.pushTags('origin');
        process.chdir(twoKeyProtocolDist);
        if (process.env.NODE_ENV === 'production') {
          await runProcess('npm', ['publish']);
        } else {
          await runProcess('npm', ['publish', '--tag', contractsStatus.current]);
        }
        await twoKeyProtocolLibGit.push('origin', contractsStatus.current);
    } else {
      process.exit(0);
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

const buildSubmodules = async(contracts) => {
  await runProcess(path.join(__dirname, 'node_modules/.bin/webpack'), ['--config', './webpack.config.submodules.js', '--mode production', '--colors']);
  // TODO: Add implementation for updateIPFSHashes
  await updateIPFSHashes(contracts);
};

async function main() {
  contractsStatus = await contractsGit.status(); // Fetching branch
  const mode = process.argv[2];
  switch (mode) {
    case '--update':
      try {
          //truffle migrate --network=plasma-azure --f 4 update TwoKeyPlasmaEvents

          await restoreFromArchive();
        const networks = process.argv[3];
        const contractName = process.argv[4];
        let str = contractName.toString()+".json";
        console.log(str);
        //truffle migrate --network=dev-local --f 4 update
        fs.unlinkSync(path.join(buildPath, str));
        await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'),['migrate',`--network=${networks}`,'--f', 4,'update',contractName]);
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
          deployedTo[truffleNetworks[networks[i]].network_id.toString()] = truffleNetworks[networks[i]].network_id;
          /* eslint-enable no-await-in-loop */
          if(networks[i] === 'public.test.k8s' || networks[i] === 'public.test.k8s-hdwallet' || networks[i] == 'ropsten') {
              flag = true;
          }
        }

        if(flag) {
            Console.log('Generating new contracts_version-develop.json for 2key-protocol and config.json file for 2key-backend...');
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
    case '--migration3': {
      try {
        const networks = process.argv[3].split(',');
        runMigration3(networks[0]);
        // process.exit(0);
      } catch (e) {
        console.log(e);
      }
      break;
    }
    case '--test':
      test();
      break;
    case '--generate':
      await generateSOLInterface();
      process.exit(0);
      break;
    case '--archive':
      archiveBuild();
      process.exit(0);
      break;
    case '--extract':
      restoreFromArchive();
      process.exit(0);
      break;
    case '--ledger':
      ledgerProvider('https://ropsten.infura.io/v3/71d39c30bc984e8a8a0d8adca84620ad', { networkId: 3 });
      process.exit(0);
      break;
    case '--submodules':
      const contracts = await generateSOLInterface();
      await buildSubmodules(contracts);
      // deployment = true;
      // const [{ hash: newTwoKeyVersionHandler }] = await ipfsAdd(`{"253dcdcca641a8a4d597befa7c775e716aa6cfd6749e19968b67133f44eef042":{"acquisition":"QmdqGiATMYprikeDF2Lf4mkgjgRiEupoqq7okrnkSJJcYn","dao":"QmQCf4t9smx7mzXWYgi7u1dr1B4EqwpdwsVXBwfgYG24Yy"},"cba508abbecc7f07ea7f5303279b631c418db248257c51800b5beeb0c13663cb":{"acquisition":"QmXnYtpaN5JfSLZuQtMNhpsk7SK34Ut54wPQbBrxFirH8R","dao":"QmSA5fwUWQpZsFEvaz5XMnfgiUpaDS7pD6Vxv2f45ikCDW"},"54395b0f794d6079335aacea55d7db03dec4285dc681e78fcdc8d51dc8aa8152":{"acquisition":"QmNazkNa3Qo4pZebUmn9yjzaaHFRbFqMXFu6Wf9PVF4UNz","dao":"QmXDQVWwkm8LvJqNKgDtiK1VxLcamPbAgo5AEZ25GTbeWZ"},"dd576626cd5d3ca4898890331bb9733c495148186a2467f8e52db182087c83a9":{"acquisition":"QmPt6HwXmUdqK69w6o5bmcQsPbMHY23b32SztZvuGcmsF3","dao":"QmTCWFW67APiKHgWKFtytC1Kvv48CFmgnX8WmqzcGL9Z5s"},"b95db734153601ebd91c3fc5d041447e040bb771bd20d6b80213e08b9e238515":{"acquisition":"Qmchw5SNHs6YYDPARLembn6YwK9jvhvpsSahKV1PyHoHfx","dao":"QmbDtG6YYHJrjLwBesFofZXH6SJe6CDVHu9d8Mdt3Aik7F"},"1a2af7b02748e7462959923c220529bba6e4ee1a56b00203e34a3ef5a7d23056":{"acquisition":"Qmds9mTGGmRUHa6YZrY1RFV4vzRYw5pajDKhUCVQkcSWYv","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo"},"1d9af579862171c413319789a12c40874d98d5a04f159c462902c65d02beec2c":{"acquisition":"QmPyT9nS1Avo8vAEfemMPZhSC4Eqg6gDd4TvYD4AC5w3yQ","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo"},"09a048aac4a7e364da1d608b3112f384edb9973d46397b8da91b276db1281b47":{"acquisition":"QmNzwvVttTEQEQd4BZP98TjuQ3QVhnk1dXUi6mGk7ogRir","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo"},"94bfe4f3afd5c27ed106589026e5091bba8b93fb0d716064c81754be07bff863":{"acquisition":"QmSyxA6N49k4Upog8KFmtZj5BHx6vi9oeGwMqPHZCvJNAf","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo"},"4a40eaa21b8f96ade30d7d10e468451a5840bc0aa98c19f4e2c5f0bd5e6c6e25":{"acquisition":"QmS6uGCJujCiSu2wPWZXV89ZMJJmNjwnJNvK1W5gAxkbqs","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo"},"8534ef61c401a6d492835759454771f2977b838d639516414364163e4277912e":{"acquisition":"QmZoAb8a8QgSvcS3zEMHjUDyTh7nXqfW7vs8BYgqasnYgP","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo"},"f98da2d5421c49b035df7509ef30703bda26abd7e267a670261eb80c7253be43":{"acquisition":"QmdkWFw8j6LQc98To6r9B9GnEWiMEr4Pi3JB6RWpkPwBKJ","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmeMgNFTSaSA4SY46rH1fG7ui6Kc2PZAvEvHkeMYmPuDGZ"},"196e35e0239ab0caf73ca1f1ec1dfa63adeb0ca4e38047c0a7115bf870539c00":{"acquisition":"QmUqmnrKURaGga4UZ52pNUJbi7uzwtBM43EBD3EmwAATUs","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmeFYKBynXuVBpXjnw9fdyKb12EZwF2xBPWjG7Ko5yRatj"},"f02330650bc7e75a21e0d040a111393532f1f719c7ba6e39497c42f89cfd693a":{"acquisition":"QmQbwKi84seQ9u2ukNc8cMD85FscNXVk8VSSE9wXdF7nQx","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmbQpbwJL1XscbWAsH4mJNiJENjTttjjAFtiTxeCByBAVb"},"419c0caf45d62fe18f8852b4f4e0c8b7236c98a4c3ade562372ea4e83ff4f93a":{"acquisition":"Qmeer38qM8VRvJGQV1cpdQ9QbibU9USU6GMWSCyWSc55pB","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmeA8azoLKo5znGomUgGGDPYC2AxLgd1MmFnERDwWGxtkY"},"d378403afd8d64ed0252034383e27151158a99731676bb79dc1c2c3567b07d57":{"acquisition":"QmVvJKT3SQtp5at58ARWx88ePyCTGBNNmd1xunLRZCnfgK","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmNTuWehSAU2JVnjrkdQBxqbp2x568KY1NHVDX3NydHuQm"},"ad0bcaee066aa38f2234d88ca45d363b6ed44f6388ce24347e96feb1c563c08b":{"acquisition":"QmSEiKnxcnxBAdGBDTtaBBXU51SfaB6P2cMBzhosqTneCL","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmakDEdxyqkFsnkH3omf45Q2Fz8TFzzkqtfgRimK5GM5aH"},"99aade4037aa6ae9e75837098c7f44298b7ce568868e83453220e3c1960b4535":{"acquisition":"Qmb6GUz9ZHtKyV8axLCT5ujgCayRcRST5CsFXJbgsZPUtE","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"Qmc5dm7wFEuBZs5cMYsMgaGHZsr4zjghfHBz65R73nbjhm"},"0575ca2596b98fc49bdaf2d0e7d054ad82543cea6c89d95855cace8cd260489d":{"acquisition":"QmU3UAjrzGsHFBZeotvaxdM52N3hvtCRCmCmyAg4q4z3Rm","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmRi1fDGWvuvH96PpYc7Gb6yFVkKGePKnkE4bscGdkxRu4"},"5dbfb5f696a7bce22dad685be2570f51ac14649f939811ab0c67b1ad968b3900":{"acquisition":"QmPJfesVvysSDoz26PRZuqPuwjZ68v6P7NUR9Hx9PMgmyc","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmZAPHWiBmob5U7cTMdJCpDm1nN4gzuyzmkkG5e2v9S1vx"},"9b35c55e90ad14e339789174a27b279b7bf94db757642200961ebc7a94178a05":{"acquisition":"QmRGoFDsGBNVdEdjqnFnawA3j72vQRhruwkDZMUKvTfCJZ","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmS6APo4RHQDpQ7eBEMF5G9c9Z7FzihrWr1dY4EqPcV44K"},"4f72518381943bde1743ba5ac3e10f7277f9b8882b40d741b5cbfb1d8666bdd6":{"acquisition":"QmVE9pvx3zFa9ziWELhiRuAGReR9K12htoDZDxkfHnPGLu","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmaQBo8HpyHePjuh5uB4hYk8nsZASQyB3CuXxCPWJUtT3A"},"d80439e0b245d5a8f67cbf6d2887b5abfa40ca04b44615d28d2497865ce5b94b":{"acquisition":"QmSRJWaNxUF91ocgxJpDrViTAbTZN6UbLcoLMTRsVSEwjS","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmQ8edkhMAHkJ3MocejHTZRLuGdwEbxxrpQP3djDeuod9y"},"333893fd3ff5aad87ef81558181a3b1d3c53d8b74cc2ba4318b1e977e31c29c4":{"acquisition":"QmfLVvdaRSVPqhtxyapUdp7tZFXr28yKiq4uLjbAgSxfhC","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmYZMaddRBijrsySBDmXCU6ckcxEo6w3Cs6zUbFTB67JEq"},"5886d6647d520582733675cab35b17c441c343e99ff5c017e9cb5bccaba02745":{"acquisition":"QmPrMWtWh6JfBf8ayVakcP7LZB6mBU3vVZBgaLB8RZ7QVT","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmeV6k3yLha1oqFFFAHn48qSvVheQzt8qjJ1UU41FBmVSJ"},"bc1e7c59155dced0419c55c1f60f7b6e476fa58b85281ef269e5404f944f62be":{"acquisition":"QmUMv9pTPW5GhFiuP1kqKy3eQpXVJuf8GJDHG2BRyniH8S","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmfMPA7iZyQsvehGxfNctEpcKwKNau2N4CksnxDHjuinNK"},"a2579abfa068f21304713bcd2fbc84d022ac4933556110af9eea5085cc610716":{"acquisition":"QmVtbXE9UdRWzMXLk1a8iRpo6fX6L2GStoex1snot9buHD","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmVBzZ8JBxJN5RK7Xbkdi45EKYb2SycaTjRghY7hzx9BK7"},"85f77a4618134d8c6e31430b0926c21d6056fc6208e81d920d207980aea6a760":{"acquisition":"QmTGChnoVQAM6xgM4sGqngiNXFoBoFPRCAQFGwJ1Pn8We8","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmTSH48BRjNWiGyTD8hEBFm7jVrMtWDVMzMArFtztpm5bH"},"4afe5473634107d5590e0fb6a58e26524a01e237fb656203620c2dbffb70a431":{"acquisition":"QmVRrTtL12DNLdXKm9J7kxGyXohXiJZ933VHkvCys8QsGY","dao":"QmQW2oY3FDJG5QAjKXyVMSdnoKwRgQaPcGAsvPtE5tyQNo","donation":"QmThRrUocU3eckCxVaHY9Y74yCUwvRdmKgnqepYH2e9FSH"}}`);
      // fs.writeFileSync(path.join(twoKeyProtocolDir, 'versions.json'), JSON.stringify({ TwoKeyVersionHandler: newTwoKeyVersionHandler }, null, 4));    
      process.exit(0);
      break;
    default:
      await deploy();
      process.exit(0);
  }
}

main().catch((e) => {
  console.log(e);
  process.exit(1);
});
