// Allows us to use ES6 in our migrations and tests.
require('babel-register')
// https://github.com/trufflesuite/truffle-hdwallet-provider
var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "laundry version question endless august scatter desert crew memory toy attract cruel";
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
