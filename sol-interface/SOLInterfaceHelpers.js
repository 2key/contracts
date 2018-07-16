const fs = require('fs');
const path = require('path');
const util = require('util');
const compressor = require('node-minify');
const simpleGit = require('simple-git')

const readdir = util.promisify(fs.readdir);
const buildPath = path.join(__dirname, 'build', 'contracts');
const abiPath = path.join(__dirname, 'sol-interface');
const actions = {};

// console.log(process.env);
// process.env.GIT_DIR = abiPath;
const git = simpleGit(abiPath);
// const git = simpleGit(process.env.GIT_DIR.replace('/.git', ''));

const getStatus = new Promise((resolve, reject) => {
  git.status((err, status) => {
    if (err) {
      reject(err);
    } else {
      resolve(status);
    }
  });
});

const setAction = {
  generate: () => { actions.doGenerate = true },
  commit: () => { actions.doCommit = true },
  tag: () => { actions.doTag = true },
  push: () => { actions.doPush = true },
};

process.argv.forEach(arg => {
  if (setAction.hasOwnProperty(arg)) {
    setAction[arg]();
  }
});

console.log('actions', actions);

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
  getStatus.then(changes => {
    if (changes.files && changes.files.length) {
      console.log(changes);
      const mainCommitMsg = fs.readFileSync(path.join(__dirname, '.git/COMMIT_EDITMSG'), { encoding: 'utf-8'});
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

if (actions.doGenerate) {
  generateSOLInterface();
} else if (actions.doCommit) {
  commitSOLInterface();
} else if (actions.doTag) {

} else if (actions.doPush) {

} else {
  console.log('Not enough arguments!');
  process.exit(1);
}