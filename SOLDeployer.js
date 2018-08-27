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
const twoKeyProtocolDir = path.join(__dirname, 'build', '2key-protocol');
const truffleTemplatePath = path.join(__dirname, 'truffle-template.js');
const truffleConfigPath = path.join(__dirname, 'truffle.js');

const contractsGit = simpleGit();
const twoKeyProtocolGit = simpleGit(twoKeyProtocolDir);

const unlinkTruffleConfig = () => {
  if (fs.existsSync(truffleConfigPath)) {
    fs.unlinkSync(truffleConfigPath);
  }
};

async function handleExit(p) {
  console.log(p);
  unlinkTruffleConfig();
  await contractsGit.reset('hard');
  await twoKeyProtocolGit.reset('hard');
  process.exit();
}

process.on('exit', handleExit);
process.on('SIGINT', handleExit);
process.on('SIGUSR1', handleExit);
process.on('SIGUSR2', handleExit);
process.on('uncaughtException', handleExit);

const generateSOLInterface = () => new Promise((resolve, reject) => {
  if (fs.existsSync(buildPath)) {
    const contracts = {
      // version: version.join('.'),
      // date: new Date().toDateString(),
      // contracts: {},
    };
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
              ? { networks } : { networks, bytecode };
          }
          // if (abi.length) {
          // contracts[contractName] =
          //  { abi, networks, bytecode: Object.keys(networks).length ? undefined : bytecode }
          // contracts[contractName] = { abi, networks, bytecode }
          // }
        });
        if (!fs.existsSync(twoKeyProtocolDir)) {
          fs.mkdirSync(twoKeyProtocolDir);
        }
        const twoKeyProtocolSrcDir = path.join(twoKeyProtocolDir, 'src');
        if (!fs.existsSync(twoKeyProtocolSrcDir)) {
          fs.mkdirSync(twoKeyProtocolSrcDir);
        }
        fs.writeFileSync(path.join(twoKeyProtocolSrcDir, 'contracts/meta.ts'), `export default ${util.inspect(contracts, { depth: 10 })}`);
        // fs.writeFileSync(path.join(twoKeyProtocolSrcDir, 'abi.json'), JSON.stringify(contracts));
        // compressor.minify({
        //   compressor: 'gcc',
        //   input: path.join(twoKeyProtocolDir, 'index.js'),
        //   output: path.join(twoKeyProtocolDir, 'index.js')
        // }).then(() => {
        //   console.log('Done');
        //   resolve();
        // })
        // .catch(reject);
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

async function main() {
  try {
    await contractsGit.fetch();
    await contractsGit.submoduleUpdate();
    let contractsStatus = await contractsGit.status();
    let twoKeyProtocolStatus = await twoKeyProtocolGit.status();
    if (twoKeyProtocolStatus.current !== contractsStatus.current) {
      const twoKeyProtocolBranches = await twoKeyProtocolGit.branch();
      if (twoKeyProtocolBranches.all.find(item => item.includes(contractsStatus.current))) {
        await twoKeyProtocolGit.checkout(contractsStatus.current);
      } else {
        await twoKeyProtocolGit.checkoutLocalBranch(contractsStatus.current);
      }
    }
    await contractsGit.submoduleUpdate();
    await twoKeyProtocolGit.reset('hard');
    twoKeyProtocolStatus = await twoKeyProtocolGit.status();
    const localChanges = contractsStatus.files
      .filter(item => !(item.path.includes('build/2key-protocol')
        || (process.env.NODE_ENV === 'development' && item.path.includes(process.argv[1].split('/').pop()))));
    if (contractsStatus.behind || localChanges.length) {
      console.log('You have unsynced changes!', localChanges);
      process.exit(1);
    }
    unlinkTruffleConfig();
    console.log(process.argv);
    const truffleConfig = fs.readFileSync(truffleTemplatePath);
    // Need review this
    // rimraf.sync(buildPath);
    fs.writeFileSync(truffleConfigPath, truffleConfig);
    const networks = process.argv[2].split(',');
    // const truffleJobs = [];

    // networks.forEach((network) => {
    //   truffleJobs.push(
    //  runTruffle(['migrate', '--network', network].concat(process.argv.slice(3))));
    // });
    const l = networks.length;
    for (let i = 0; i < l; i += 1) {
      /* eslint-disable no-await-in-loop */
      await runProcess('./node_modules/.bin/truffle', ['migrate', '--network', networks[i]].concat(process.argv.slice(3)));
      /* eslint-enable no-await-in-loop */
    }
    await runProcess('./node_modules/.bin/typechain', ['--force', '--outDir', path.join(twoKeyProtocolDir, 'src/contracts'), `${buildPath}/*.json`]);
    unlinkTruffleConfig();
    await generateSOLInterface();
    await runProcess('./node_modules/.bin/webpack');
    contractsStatus = await contractsGit.status();
    twoKeyProtocolStatus = await twoKeyProtocolGit.status();
    const network = networks.join('/');
    const now = moment();
    const commit = `SOL Deployed to ${network} ${now.format('lll')}`;
    const tag = `${network}-${now.format('YYYYMMDDHHmmss')}`;
    console.log(commit, tag);
    await twoKeyProtocolGit.add(twoKeyProtocolStatus.files.map(item => item.path));
    await twoKeyProtocolGit.commit(commit);
    await contractsGit.add(contractsStatus.files.map(item => item.path));
    await contractsGit.commit(commit);
    await twoKeyProtocolGit.addTag(tag);
    await contractsGit.addTag(tag);
    await twoKeyProtocolGit.push('origin', contractsStatus.current);
    await contractsGit.push('origin', contractsStatus.current);
    await twoKeyProtocolGit.pushTags('origin');
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

main();
