// Allows us to use ES6 in our migrations and tests.
require('babel-register')
// https://github.com/trufflesuite/truffle-hdwallet-provider
var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "laundry version question endless august scatter desert crew memory toy attract cruel";
const pk = 'd718529bf9e0a5365e3a3545b66a612ff29be12aba366b6e6e919bef1d3b83e2';
// make sure you have Ether on rinkeby address 0xb3fa520368f2df7bed4df5185101f303f6c7decc


module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8500,
      // provider: new HDWalletProvider(mnemonic, "http://localhost:8500"),
      network_id: '*', // Match any network id
      gas: 7000000,
      gasPrice: 2000000000
    },
    "dev-local": {
      // host: 'localhost',
      // port: 8545,
      provider: new HDWalletProvider(mnemonic, "http://localhost:8545"),
      network_id: '*', // Match any network id
      gas: 7000000,
      gasPrice: 2000000000
    },
    "dev-ap": {
      // host: 'localhost',
      // port: 8545,
      provider: new HDWalletProvider(mnemonic, "http://192.168.47.100:8545"),
      network_id: '*', // Match any network id
      gas: 7000000,
      gasPrice: 2000000000
    },
    "dev-shlomi": {
      // host: 'localhost',
      // port: 8545,
      provider: new HDWalletProvider(mnemonic, "http://18.233.2.70:8500"),
      network_id: '*', // Match any network id
      gas: 7000000,
      gasPrice: 2000000000
    },
    "geth-local": {
      provider: new HDWalletProvider(mnemonic, "http://localhost:8545"),
      network_id: '*',
      gas: 7000000,
      gasPrice: 2000000000
    },
    "poc-dev": {
      provider: new HDWalletProvider(mnemonic, "http://poc-dev.2key.network:3000"),
      network_id: '*',
      gas: 7000000,
      gasPrice: 2000000000
    },
    "rinkeby-infura": {
      provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/6rAARDbMXpJlwODa2kbk"),
      network_id: '*',
      gas: 7000000,
      gasPrice: 2000000000
    },
    plasma: {
      host: 'localhost',
      port: 8888,
      network_id: '*' // Match any network id
    }
  }
}
