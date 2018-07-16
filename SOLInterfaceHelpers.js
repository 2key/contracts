const fs = require('fs');
const path = require('path');
const util = require('util');
const compressor = require('node-minify');
const simpleGit = require('simple-git/promise');
const childProcess = require('child_process');

const readdir = util.promisify(fs.readdir);
const buildPath = path.join(__dirname, 'build', 'contracts');
const abiPath = path.join(__dirname, 'build', 'sol-interface');

const mainGit = simpleGit();
const solGit = simpleGit(abiPath);

const generateSOLInterface = () => {
  if (fs.existsSync(buildPath)) {
    const contracts = {
      version: Date.now(),
      date: new Date().toDateString(),
    };
    readdir(buildPath).then(files => {
      files.forEach(file => {
        const { abi, networks, contractName } = JSON.parse(fs.readFileSync(path.join(buildPath, file)))
        if (abi.length && Object.keys(networks).length) {
          contracts[contractName] = { abi, address: Object.values(networks)[0].address }
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
        console.log('Done')
      });
    });
  }
}

const commitSOLInterface = () => {
  gitHelpers.status()
    .then(changes => {
      if (changes.files && changes.files.length) {
        console.log(changes);
        const mainCommitMsg = fs.readFileSync(path.join(__dirname, '.git/COMMIT_EDITMSG'), { encoding: 'utf-8' });
        console.log('Message', mainCommitMsg);
        git.add(changes.files.map(file => path.join(abiPath, file.path)), (err, result) => {
          if (err) {
            console.warn('Add failed:', err);
            process.exit(1);
          } else {
            console.log(result);
            git.commit(mainCommitMsg, (commitErr, commitResult) => {
              if (commitErr) {
                console.warn('Commit failed:', commitErr);
                process.exit(1);
              } else {
                console.log(`${mainCommitMsg}commited`);
              }
            });
          }
        });
      } else {
        console.log('Nothing changed');
      }
    })
    .catch(err => {
      console.warn('GIT STATUS ERROR:', err);
      process.exit(1);
    });
}

async function main() {
  try {
    await mainGit.fetch();
    const mainStatus = await mainGit.status();
    const solStatus = await solGit.status();
    if (solStatus.current !== mainStatus.current) {
      const solBranches = await solGit.branch();
      if (solBranches.all.find(item => item.includes(mainStatus.current))) {
        await solGit.checkout(mainStatus.current);
      } else {
        await solGit.checkoutBranch(mainStatus.current, solStatus.current);
      }
    }
    await mainGit.submoduleUpdate();
    console.log(mainStatus);
    const localChanges = mainStatus.files
      .filter(item => !(item.path.includes('build/sol-interface')
        || (process.env.NODE_ENV === 'development' && item.path.includes('SOLInterfaceHelpers.js'))));
    if (mainStatus.behind || localChanges.length) {
      console.log('You have unsynced changes!', localChanges);
      process.exit(1);
    }
    console.log(process.argv);
    const truffleStatus = childProcess.execSync(`truffle ${process.argv.slice(2).join(' ')}`);
    console.log(truffleStatus);
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
    mainGit.reset('hard');
  }
}

main();
