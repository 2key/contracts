const fs = require('fs');
const path = require('path');
const util = require('util');
const tar = require('tar');
const rimraf = require('rimraf');
// const compressor = require('node-minify');
const simpleGit = require('simple-git/promise');
const childProcess = require('child_process');
const moment = require('moment');
const whitelist = require('./ContractDeploymentWhiteList.json');

const readdir = util.promisify(fs.readdir);
const buildPath = path.join(__dirname, 'build', 'contracts');
const buildBackupPath = path.join(__dirname, 'build', 'contracts.bak');
const twoKeyProtocolDir = path.join(__dirname, '2key-protocol-src');
const buildArchPath = path.join(twoKeyProtocolDir, 'contracts.tar.gz');
const twoKeyProtocolLibDir = path.join(__dirname, 'build', '2key-protocol-npm');

const deploymentHistoryPath = path.join(__dirname, 'history.json');

const contractsGit = simpleGit();
const twoKeyProtocolLibGit = simpleGit(twoKeyProtocolLibDir);

async function handleExit(p) {
  console.log(p);
  // if (p !== 0 && (process.argv[2] !== '--migrate' && process.argv[2] !== '--test')) {
  //   await contractsGit.reset('hard');
  //   await twoKeyProtocolLibGit.reset('hard');
  // }
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
        if (Object.keys(networks).length) {
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
    console.log('Archive', buildPath, buildArchPath);
    if (fs.existsSync(buildPath)) {
      tar.c({
        gzip: true, sync: true, cwd: path.join(__dirname, 'build')
      }, ['contracts'])
        .pipe(fs.createWriteStream(buildArchPath));


      await rmDir(buildPath);
      if (fs.existsSync(buildBackupPath)) {
        fs.renameSync(buildBackupPath, buildPath);
      }
    }
    resolve();
  } catch (err) {
    reject(err);
  }
});

const restoreFromArchive = () => {
  if (fs.existsSync(buildPath)) {
    fs.renameSync(buildPath, buildBackupPath);
  }
  if (fs.existsSync(buildArchPath)) {
    tar.x({ gzip: true, sync: true, cwd: path.join(__dirname, 'build') });
  }
};

const generateSOLInterface = () => new Promise((resolve, reject) => {
  if (fs.existsSync(buildPath)) {
    const contracts = {};
    const json = {};
    readdir(buildPath).then((files) => {
      try {
        files.forEach((file) => {
          const {
            networks, contractName, bytecode, abi
          } = JSON.parse(fs.readFileSync(path.join(buildPath, file)));
          if (whitelist[contractName]) {
            // contracts[contractName] = whitelist[contractName].deployed
            //   ? { abi, networks } : { abi, networks, bytecode };
            contracts[contractName] = whitelist[contractName].singletone
              ? {networks, name: contractName} : {bytecode, abi, networks, name: contractName};
            json[contractName] = whitelist[contractName].singletone
              ? {networks, abi, name: contractName} : {bytecode, abi, networks, name: contractName};
          }
        });
        console.log('Writing meta.ts...');
        fs.writeFileSync(path.join(twoKeyProtocolDir, 'contracts/meta.ts'), `export default ${util.inspect(contracts, {depth: 10})}`);
        console.log('Writing contracts.json...');
        fs.writeFileSync(path.join(twoKeyProtocolDir, 'contracts.json'), JSON.stringify(json, null, 2));
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
      .filter(item => !(item.path.includes('build/2key-protocol-npm')
        || (process.env.NODE_ENV === 'development' && item.path.includes(process.argv[1].split('/').pop()))));
    if (contractsStatus.behind || localChanges.length) {
      console.log('You have unsynced changes!', localChanges);
      process.exit(1);
    }
    console.log(process.argv);
    const local = process.argv[2].includes('local');
    if (!local) {
      await test();
    }

    // TODO: Add build/contracts backup
    restoreFromArchive();

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
    await runProcess(path.join(__dirname, 'node_modules/.bin/typechain'), ['--force', '--outDir', path.join(twoKeyProtocolDir, 'contracts'), `${buildPath}/*.json`]);
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
    if (!local) {
      await twoKeyProtocolLibGit.addTag(tag);
      await contractsGit.addTag(tag);
      await twoKeyProtocolLibGit.pushTags('origin');
      await contractsGit.pushTags('origin');
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
    await runProcess('node', ['-r', 'dotenv/config', './node_modules/.bin/mocha', '--exit', '--bail', '-r', 'ts-node/register', '2key-protocol-src/**/*.spec.ts']);
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
    case '--migrate':
      try {
        const networks = process.argv[3].split(',');
        const l = networks.length;
        for (let i = 0; i < l; i += 1) {
          /* eslint-disable no-await-in-loop */
          await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--network', networks[i]].concat(process.argv.slice(4)));
          /* eslint-enable no-await-in-loop */
        }
        await generateSOLInterface();
        await runProcess(path.join(__dirname, 'node_modules/.bin/typechain'), ['--force', '--outDir', path.join(twoKeyProtocolDir, 'contracts'), `${buildPath}/*.json`]);
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
    default:
      deploy();
  }
}

main();
