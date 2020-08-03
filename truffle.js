// Allows us to use ES6 in our migrations and tests.
require('babel-register');
require('regenerator-runtime/runtime');

const HDWalletProvider = require('truffle-hdwallet-provider');
const LedgerProvider = require('./LedgerProvider');

const config = require('./configurationFiles/accountsConfig.json');

const mnemonic =  process.env.MNEMONIC || config.mnemonic;

const rpcs = {
    'test-public' : 'https://rpc-dev.public.test.k8s.2key.net',
    'test-private' : 'https://rpc-dev.private.test.k8s.2key.net',
    'staging-public' : 'https://rpc-staging.public.test.k8s.2key.net',
    'staging-private' : 'https://rpc-staging.private.test.k8s.2key.net',
    'prod-public' : 'https://rpc.public.prod.k8s.2key.net',
    'prod-private' : 'https://rpc.private.prod.k8s.2key.net',
    'dev-ganache': 'https://localhost:7545',
    'infura-ropsten' : `https://ropsten.infura.io/v3/${config.infura_id}`
};

const ids = {
    'test-public' : 3,
    'test-private' : 181,
    'staging-public' : 3,
    'staging-private' : 182,
    'prod-public' : 1,
    'prod-private' : 180,
    'dev-ganache': 5777,
    'infura-ropsten': 3
};

const createLedgerProvider = (rpc, id) => () =>
    LedgerProvider(rpc, {
        networkId: id,
        // https://github.com/LedgerHQ/ledgerjs/issues/200
        // path: "44'/60'/0'/0", --> Legacy / MEW derivation path
        // path: "44\'/60\'/[index]\'/0/0", --> Ledger-Live derivation path
        path: "44\'/60\'/0\'/0/0",
        // askConfirm: true,
        askConfirm: false,
        accountsLength: 1,
        accountsOffset: 0,
    });


module.exports = {
  plugins: ["truffle-security"],

  networks: {
      'dev-ganache': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["dev-ganache"]),
          skipDryRun: true,
          network_id: ids["dev-ganache"],
          gas: 8000000,
          gasPrice: 120000000000,
      },
      'plasma-ganache': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["dev-ganache"]),
          skipDryRun: true,
          network_id: ids["dev-ganache"],
          gas: 8000000,
          gasPrice: 120000000000,
      },

      'dev-local': {
          provider: () => new HDWalletProvider(mnemonic, 'http://localhost:8545'),
          network_id: 8086, // Match any network id
          gas: 8000000,
          gasPrice: 15500000000
      },

      'plasma-test-local': {
          provider: () => new HDWalletProvider(mnemonic, 'http://localhost:18545'),
          network_id: 8087, // Match any network id
          gas: 8000000,
          gasPrice: 0
      },

      'public.test-ledger': {
          provider: createLedgerProvider(rpcs["test-public"], ids["test-public"]),
          skipDryRun: true,
          network_id: ids["test-public"],
          gas: 8000000,
          gasPrice: 120000000000,
      },

      'public.test-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["test-public"]),
          skipDryRun: true,
          network_id: ids["test-public"],
          gas: 8000000,
          gasPrice: 120000000000,
      },

      'private.test-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["test-private"]),
          skipDryRun: true,
          network_id: ids["test-private"],
          gas: 8000000,
          gasPrice: 0,
      },

      'private.test-ledger': {
          provider: createLedgerProvider(rpcs["test-private"], ids["test-private"]),
          skipDryRun: true,
          network_id: ids["test-private"],
          gas: 8000000,
          gasPrice: 0,
      },

      'public.staging-ledger': {
          provider: createLedgerProvider(rpcs["staging-public"], ids["staging-public"]),
          skipDryRun: true,
          network_id: ids["staging-public"],
          gas: 8000000,
          gasPrice: 120000000000,
      },

      'public.staging-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["staging-public"]),
          skipDryRun: true,
          network_id: ids["staging-public"],
          gas: 8000000,
          gasPrice: 40000000000,
      },

      'private.staging-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["staging-private"]),
          skipDryRun: true,
          network_id: ids["staging-private"],
          gas: 7900000,
          gasPrice: 0,
      },

      'private.staging-ledger': {
          provider: createLedgerProvider(rpcs["staging-private"], ids["staging-private"]),
          skipDryRun: true,
          network_id: ids["staging-private"],
          gas: 7900000,
          gasPrice: 0,
      },

      'public.prod-ledger': {
          provider: createLedgerProvider(rpcs["prod-public"], ids["prod-public"]),
          skipDryRun: true,
          network_id: ids["prod-public"],
          gas: 8000000,
          gasPrice: 51000000000,
      },

      'public.prod-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["prod-public"]),
          skipDryRun: true,
          network_id: ids["prod-public"],
          gas: 9000000,
          gasPrice: 40000000000,
      },

      'private.prod-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["prod-private"]),
          skipDryRun: true,
          network_id: ids["prod-private"],
          gas: 8000000,
          gasPrice: 0,
      },

      'private.prod-ledger': {
          provider: createLedgerProvider(rpcs["prod-private"], ids["prod-private"]),
          skipDryRun: true,
          network_id: ids["prod-private"],
          gas: 9000000,
          gasPrice: 0,
      },

      // 'plasma-test-local': {
      //     provider: () => new HDWalletProvider(mnemonic, 'https://rpc-staging.private.test.k8s.2key.net'),
      //     network_id: 182,
      //     gas: 7900000,
      //     gasPrice: '0x0',
      //     skipDryRun: true
      // },

      'public.prod-ropsten-hdwallet': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["staging-public"]),
          skipDryRun: true,
          network_id: ids["staging-public"],
          gas: 7900000,
          gasPrice: 120000000000,
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
