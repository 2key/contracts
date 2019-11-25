// Allows us to use ES6 in our migrations and tests.
require('babel-register');
require('regenerator-runtime/runtime');

// const HDWalletProvider = require('truffle-hdwallet-provider');
const LedgerWalletProvider = require('truffle-ledger-provider');

const HDWalletProvider = require('truffle-hdwallet-provider');
// const HDWalletProvider = require('./HDWalletProvider');
const LedgerProvider = require('./LedgerProvider');

const config = require('./configurationFiles/accountsConfig.json');

const mnemonic =  process.env.MNEMONIC || config.mnemonic;
const infuraApiKey = config.infuraApiKey;

const ledgerOptions = {
  networkId: 3, // ropsten testnet
  accountsOffset: 0 // we use the first address
};

/*

#### STAGING PLASMA

**RPC**:  https://rpc.private.test.k8s.2key.net:443

**WS**:   wss://ws.private.test.k8s.2key.net:443


#### RINKEBY

**RPC**:  https://rpc.public.test.k8s.2key.net:443

**WS**:   wss://ws.public.test.k8s.2key.net:443


#### PROD-PLASMA

**RPC**:  https://rpc.private.prod.k8s.2key.net:443

**WS**:   wss://ws.private.prod.k8s.2key.net:443


#### MAIN-NET

**RPC**:  https://rpc.public.prod.k8s.2key.net:443

**WS**:   wss://ws.public.prod.k8s.2key.net:443

*/

module.exports = {

  plugins: ["truffle-security"],

  networks: {
      'dev-local': {
          provider: () => new HDWalletProvider(mnemonic, 'http://localhost:8545'),
          network_id: 8086, // Match any network id
          gas: 8000000,
          gasPrice: 2000000000
      },

      'development': {
          host: "localhost",
          port: 8545,
          network_id: "1573128942823", // Match any network id
          gas: 10000000,
          gasPrice: 2000000000
      },


      'public.test.k8s': {
          provider: () => LedgerProvider('https://rpc.public.test.k8s.2key.net', {
              networkId: 3,
              // https://github.com/LedgerHQ/ledgerjs/issues/200
              // path: "44'/60'/0'/0",
              path: "44\'/60\'/0\'/0/0",
              // askConfirm: true,
              askConfirm: false,
              accountsLength: 1,
              accountsOffset: 0,
          }),
          skipDryRun: true,
          network_id: 3,
          gas: 8000000,
          gasPrice: 120000000000,
      },

      'private.test.k8s': {
          provider: () => LedgerProvider('https://rpc.private.test.k8s.2key.net', {
              networkId: 98052,
              // https://github.com/LedgerHQ/ledgerjs/issues/200
              path: "44'/60'/0'/0",
              // askConfirm: true,
              askConfirm: false,
              accountsLength: 1,
              accountsOffset: 0,
          }),
          network_id: 98052,
          gas: 7000000,
          skipDryRun: true,
          gasPrice: 0
      },


      'private.test.k8s-dev': {
          provider: () => LedgerProvider('https://rpc-dev.private.test.k8s.2key.net', {
              networkId: 181,
              // https://github.com/LedgerHQ/ledgerjs/issues/200
              path: "44'/60'/0'/0",
              // askConfirm: true,
              askConfirm: false,
              accountsLength: 1,
              accountsOffset: 0,
          }),
          network_id: 181,
          gas: 8000000,
          skipDryRun: true,
          gasPrice: 0x0
      },


      'public.test.k8s-dev': {
          provider: () => LedgerProvider('https://rpc-dev.public.test.k8s.2key.net', {
              networkId: 3,
              // https://github.com/LedgerHQ/ledgerjs/issues/200
              path: "44'/60'/0'/0",
              //path: "44\'/60\'/0\'/0/0",
              // askConfirm: true,
              askConfirm: false,
              accountsLength: 1,
              accountsOffset: 0,
          }),
          skipDryRun: true,
          network_id: 3,
          gas: 8000000,
          gasPrice: 120000000000,
      },

      'public.test.k8s-hdwallet-dev': {
          provider: () => new HDWalletProvider(mnemonic, 'https://rpc-dev.public.test.k8s.2key.net'),
          skipDryRun: true,
          network_id: 3,
          gas: 8000000,
          gasPrice: 120000000000,
      },

      'private.test.k8s-hdwallet-dev': {
          provider: () => new HDWalletProvider(mnemonic, 'https://rpc-dev.private.test.k8s.2key.net'),
          network_id: 181,
          gas: 8000000,
          gasPrice: '0x0',
          skipDryRun: true
          // gasPrice: 100000000000,
          // gasPrice: 2000000000
      },



      'public.test.k8s-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, 'https://rpc.public.test.k8s.2key.net'),
          network_id: 3,
          gas: 8000000,
          gasPrice: 80000000000,
          skipDryRun: true
      },

      'private.test.k8s-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, 'https://rpc.private.test.k8s.2key.net'),
          network_id: 98052,
          gas: 8000000,
          gasPrice: '0x0',
          skipDryRun: true
          // gasPrice: 100000000000,
          // gasPrice: 2000000000
      },

      'plasma-test-local': {
          provider: () => new HDWalletProvider(mnemonic, 'https://rpc-dev.private.test.k8s.2key.net'),
          network_id: 181,
          gas: 8000000,
          gasPrice: '0x0',
          skipDryRun: true

      },
  },

    compilers: {
          solc: {
              path: "soljson-v0.4.24+commit.e67f0147.js",
              version: "0.4.24",
              build: "commit.e67f0147",
              settings: {
                  optimizer: {
                      enabled: true,
                      runs: 200,
                      evmVersion: "byzantium"
                  }
              }
          }
    }
};
