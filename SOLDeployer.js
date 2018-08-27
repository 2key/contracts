const fs = require('fs');
const path = require('path');
const util = require('util');
// const compressor = require('node-minify');
const simpleGit = require('simple-git/promise');
const childProcess = require('child_process');
const moment = require('moment');
const whitelist = require('./whitelist.json');

const readdir = util.promisify(fs.readdir);
const buildPath = path.join(__dirname, 'build', 'contracts');
const twoKeyProtocolDir = path.join(__dirname, '2key-protocol');
const twoKeyProtocolLibDir = path.join(__dirname, 'build', '2key-protocol');

const contractsGit = simpleGit();
const twoKeyProtocolLibGit = simpleGit(twoKeyProtocolLibDir);

async function handleExit(p) {
  console.log(p);
  if (p !== 0) {
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

const generateSOLInterface = () => new Promise((resolve, reject) => {
  if (fs.existsSync(buildPath)) {
    const contracts = {};
    readdir(buildPath).then((files) => {
      try {
        files.forEach((file) => {
          const {
            networks, contractName, bytecode,
          } = JSON.parse(fs.readFileSync(path.join(buildPath, file)));
          if (whitelist[contractName]) {
            // contracts[contractName] = whitelist[contractName].deployed
            //   ? { abi, networks } : { abi, networks, bytecode };
            contracts[contractName] = whitelist[contractName].deployed
              ? { networks } : { bytecode };
          }
        });
        fs.writeFileSync(path.join(twoKeyProtocolDir, 'contracts/meta.ts'), `export default ${util.inspect(contracts, { depth: 10 })}`);
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
  const proc = childProcess.spawn(app, args);
  proc.stdout.on('data', (data) => {
    console.log(data.toString('utf8'));
  });
  proc.stderr.on('data', (data) => {
    console.log(data.toString('utf8'));
    reject(data);
  });
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
      .filter(item => !(item.path.includes('build/2key-protocol')
        || (process.env.NODE_ENV === 'development' && item.path.includes(process.argv[1].split('/').pop()))));
    if (contractsStatus.behind || localChanges.length) {
      console.log('You have unsynced changes!', localChanges);
      process.exit(1);
    }
    console.log(process.argv);
    const networks = process.argv[2].split(',');
    const l = networks.length;
    for (let i = 0; i < l; i += 1) {
      /* eslint-disable no-await-in-loop */
      await runProcess(path.join(__dirname, 'node_modules/.bin/truffle'), ['migrate', '--network', networks[i]].concat(process.argv.slice(3)));
      /* eslint-enable no-await-in-loop */
    }
    await generateSOLInterface();
    await runProcess(path.join(__dirname, 'node_modules/.bin/typechain'), ['--force', '--outDir', path.join(twoKeyProtocolDir, 'contracts'), `${buildPath}/*.json`]);
    await runProcess(path.join(__dirname, 'node_modules/.bin/webpack'));
    contractsStatus = await contractsGit.status();
    twoKeyProtocolStatus = await twoKeyProtocolLibGit.status();
    const network = networks.join('/');
    const now = moment();
    const commit = `SOL Deployed to ${network} ${now.format('lll')}`;
    const tag = `${network}-${now.format('YYYYMMDDHHmmss')}`;
    console.log(commit, tag);
    await twoKeyProtocolLibGit.add(twoKeyProtocolStatus.files.map(item => item.path));
    await twoKeyProtocolLibGit.commit(commit);
    await contractsGit.add(contractsStatus.files.map(item => item.path));
    await contractsGit.commit(commit);
    await twoKeyProtocolLibGit.addTag(tag);
    await contractsGit.addTag(tag);
    await twoKeyProtocolLibGit.push('origin', contractsStatus.current);
    await contractsGit.push('origin', contractsStatus.current);
    await twoKeyProtocolLibGit.pushTags('origin');
    await contractsGit.pushTags('origin');
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
    default:
      deploy();
  }
}

main();
