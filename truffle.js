// Allows us to use ES6 in our migrations and tests.
require('babel-register');
// https://github.com/trufflesuite/truffle-hdwallet-provider
const HDWalletProvider = require('truffle-hdwallet-provider');
// const HDWalletProvider = require('./WalletProvider');
const LedgerProvider = require('./LedgerProvider');

const mnemonic = 'laundry version question endless august scatter desert crew memory toy attract cruel';
const mnemonic_private = 'north depend loyal purpose because theme funny script debris divert kitchen junk diary angry method';
// make sure you have Ether on rinkeby address 0xb3fa520368f2df7bed4df5185101f303f6c7decc
const infuraApiKey = 'db719ec4fd734e798e74782bce13bbca';

const ledgerOptions = {
  networkId: 3, // ropsten testnet
  accountsOffset: 0 // we use the first address
};

module.exports = {
  networks: {
    'development': {
      host: 'localhost',
      port: 8545,
      // provider: new HDWalletProvider(mnemonic, "http://localhost:8500"),
      network_id: '*', // Match any network id
      gas: 10000000,
      gasPrice: 2000000000
    },
    'dev-ganache': {
      host: 'localhost',
      port: 8500,
      network_id: '*', // Match any network id
      gas: 8000000,
      gasPrice: 2000000000
    },
    'dev-local': {
      provider: new HDWalletProvider(mnemonic, 'http://localhost:8545'),
      network_id: 8086, // Match any network id
      gas: 8000000,
      gasPrice: 2000000000
    },
    'dev-private': {
      provider: () => new HDWalletProvider(mnemonic_private, 'http://192.168.47.101:28545'),
      // provider: () => new PKProvider(['d718529bf9e0a5365e3a3545b66a612ff29be12aba366b6e6e919bef1d3b83e2'], 'http://astring.aydnep.com.ua:8545'),
      network_id: 8087, // Match any network id
      gas: 7888888,
      gasPrice: 2000000000
    },
    'dev-ap': {
      provider: () => new HDWalletProvider(mnemonic, 'http://astring.aydnep.com.ua:8545'),
      // provider: () => new PKProvider(['d718529bf9e0a5365e3a3545b66a612ff29be12aba366b6e6e919bef1d3b83e2'], 'http://astring.aydnep.com.ua:8545'),
      network_id: 8087, // Match any network id
      gas: 7888888,
      gasPrice: 2000000000
    },
    'dev-2key': {
      provider: () => new HDWalletProvider(mnemonic, 'http://18.233.2.70:8500'),
      network_id: '*', // Match any network id
      gas: 8000000,
      gasPrice: 5000000000
    },
    'rinkeby-infura': {
      provider: () => LedgerProvider(`https://rinkeby.infura.io/v3/${infuraApiKey}`, {
        networkId: 4,
        // https://github.com/LedgerHQ/ledgerjs/issues/200
        path: "44'/60'/0'/0",
        askConfirm: true,
        accountsLength: 1,
        accountsOffset: 0,
      }),

      // provider: () => new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/v3/904c762bd6984606bf8ae7f30d7cb28c\n'),
      network_id: 4,
      gas: 7000000,
      gasPrice: 50000000000
    },
    staging: {
      provider: () => LedgerProvider(`https://ropsten.infura.io/v3/${infuraApiKey}`, {
        networkId: 3,
        // https://github.com/LedgerHQ/ledgerjs/issues/200
        path: "44'/60'/0'/0",
        askConfirm: true,
        accountsLength: 1,
        accountsOffset: 0,
      }),
      // provider: () => new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/v3/71d39c30bc984e8a8a0d8adca84620ad'),
      network_id: 3,
      gas: 8000000,
      gasPrice: 50000000000
    },
    'staging-2key': {
      provider: () => LedgerProvider('http://18.233.2.70:8500/ropsten', {
        networkId: 3,
        // https://github.com/LedgerHQ/ledgerjs/issues/200
        path: "44'/60'/0'/0",
        askConfirm: true,
        accountsLength: 1,
        accountsOffset: 0,
      }),
      // provider: () => new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/v3/71d39c30bc984e8a8a0d8adca84620ad'),
      network_id: 3,
      gas: 8000000,
      gasPrice: 50000000000
    },
    'kovan': {
      provider: () => new HDWalletProvider(mnemonic, 'https://kovan.infura.io/6rAARDbMXpJlwODa2kbk'),
      network_id: 42,
      gas: 7000000,
      gasPrice: 3000000000
    },
    'plasma-local': {
      // host: 'localhost',
      // port: 8545,
      provider: () => new HDWalletProvider(mnemonic, 'http://localhost:18545'),
      network_id: 17, // Match any network id
      gas: 7000000,
      gasPrice: 1
      // gasPrice: 2000000000
    },
    'plasma-ap': {
      // host: 'localhost',
      // port: 8545,
      provider: () => new HDWalletProvider(mnemonic, 'http://astring.aydnep.com.ua:38545'),
      network_id: 17, // Match any network id
      gas: 7000000,
      gasPrice: 1
      // gasPrice: 2000000000
    },
    'plasma-dev': {
      // host: 'localhost',
      // port: 8545,
      provider: () => new HDWalletProvider(mnemonic, 'http://192.168.47.100:8545'),
      network_id: 17, // Match any network id
      gas: 7000000,
      gasPrice: 1
      // gasPrice: 2000000000
    },
    'plasma-2key': {
      provider: () => new HDWalletProvider(mnemonic, 'http://18.233.2.70:8500/prv2'),
      gas: 7000000,
      gasPrice: 2000000000
    }
  }
};
