const fs = require('fs');
const path = require('path');
const util = require('util');
const compressor = require('node-minify');

const readdir = util.promisify(fs.readdir);

const buildPath = path.join(__dirname, 'build', 'contracts');
const abiPath = path.join(__dirname, 'build', 'sol-interface');

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