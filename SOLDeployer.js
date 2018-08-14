const fs = require('fs');
const path = require('path');
const util = require('util');
const compressor = require('node-minify');
const simpleGit = require('simple-git/promise');
const childProcess = require('child_process');
const moment = require('moment');

const readdir = util.promisify(fs.readdir);
const buildPath = path.join(__dirname, 'build', 'contracts');
const abiPath = path.join(__dirname, 'build', 'sol-interface');
const truffleTemplatePath = path.join(__dirname, 'truffle-template.js');
const truffleConfigPath = path.join(__dirname, 'truffle.js');

const contractsGit = simpleGit();
const solGit = simpleGit(abiPath);

const unlinkTruffleConfig = () => {
  if (fs.existsSync(truffleConfigPath)) {
    fs.unlinkSync(truffleConfigPath);
  }
}


async function handleExit(p) {
  console.log(p);
  unlinkTruffleConfig();
  await contractsGit.reset('hard');
  await solGit.reset('hard');
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
      version: Date.now(),
      date: new Date().toDateString(),
    };
    readdir(buildPath).then(files => {
      files.forEach(file => {
        const { abi, networks, contractName, bytecode } = JSON.parse(fs.readFileSync(path.join(buildPath, file)))
        if (abi.length) {
          contracts[contractName] = { abi, networks, bytecode }
        }
      });
      if (!fs.existsSync(abiPath)) {
        fs.mkdirSync(abiPath);
      }
      fs.writeFileSync(path.join(abiPath, 'index.js'), `module.exports = ${util.inspect(contracts, { depth: 10 })}`);
      compressor.minify({
        compressor: 'gcc',
        input: path.join(abiPath, 'index.js'),
        output: path.join(abiPath, 'index.js')
      }).then(() => {
        console.log('Done');
        resolve();
      })
      .catch(reject);
    });
  }
});

async function main() {
  try {
    await contractsGit.fetch();
    await contractsGit.submoduleUpdate();
    let contractsStatus = await contractsGit.status();
    let solStatus = await solGit.status();
    if (solStatus.current !== contractsStatus.current) {
      const solBranches = await solGit.branch();
      if (solBranches.all.find(item => item.includes(contractsStatus.current))) {
        await solGit.checkout(contractsStatus.current);
      } else {
        await solGit.checkoutLocalBranch(contractsStatus.current);
      }
    }
    await contractsGit.submoduleUpdate();
    await solGit.reset('hard');
    solStatus = await solGit.status();
    const localChanges = contractsStatus.files
      .filter(item => !(item.path.includes('build/sol-interface')
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
    console.time('truffle migrate');
    const truffle = childProcess.spawn(path.join(__dirname, 'node_modules/.bin/truffle'), process.argv.slice(2));
    truffle.stdout.on('data', data => {
      console.log(data.toString('utf8'));
    });
    truffle.stderr.on('data', data => {
      console.log(data.toString('utf8'));
      throw new Error('truffle error');
    });
    truffle.on('close', async code => {
      console.timeEnd('truffle migrate');
      console.log('truffle exit with code', code);
      unlinkTruffleConfig();
      if (code === 0) {
        const solConfigJSON = JSON.parse(fs.readFileSync(path.join(abiPath, 'package.json')));
        const version = solConfigJSON.version.split('.');
        version[version.length - 1] = parseInt(version.pop(), 10) + 1
        solConfigJSON.version = version.join('.');
        console.log('sol-interface version:', solConfigJSON.version);
        fs.writeFileSync(path.join(abiPath, 'package.json'), JSON.stringify(solConfigJSON));
        await generateSOLInterface();
        contractsStatus = await contractsGit.status();
        solStatus = await solGit.status();
        const network = process.argv[process.argv.indexOf('--network') + 1];
        const now = moment();
        const commit = `SOL Deployed to ${network} ${now.format('lll')}`
        const tag = `${network}-${now.format('YYYYMMDDHHmmss')}`;
        console.log(commit, tag);
        await solGit.add(solStatus.files.map(item => item.path));
        await solGit.commit(commit);
        await contractsGit.add(contractsStatus.files.map(item => item.path));
        await contractsGit.commit(commit);
        await solGit.addTag(tag);
        await contractsGit.addTag(tag);
        await solGit.push('origin', contractsStatus.current);
        await contractsGit.push('origin', contractsStatus.current);
        await solGit.pushTags('origin');
        await contractsGit.pushTags('origin');
      } else {
        await contractsGit.reset('hard');
        await solGit.reset('hard');
        process.exit(1);
      }
    });
    // console.log(truffleStatus.toString('utf8'));
  } catch (e) {
    if (e.output) {
      e.output.forEach(buff => {
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
