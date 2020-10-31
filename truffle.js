// Allows us to use ES6 in our migrations and tests.
require('babel-register');
require('regenerator-runtime/runtime');

const HDWalletProvider = require('truffle-hdwallet-provider');
const LedgerProvider = require('./LedgerProvider');

const config = require('./configurationFiles/accountsConfig.json');

const mnemonic =  process.env.MNEMONIC || config.mnemonic;


const rpcs = {
    'test-public' : config["test-public"],
    'test-private' : config["test-private"],
    'staging-public' : config["staging-public"],
    'staging-private' : config["staging-private"],
    'prod-public' : config["prod-public"],
    'prod-private' : config["prod-private"],
    'dev-local': config["dev-local"],
    'plasma-test-local': config["plasma-test-local"]
};

const ids = {
    'test-public' : 3,
    'test-private' : 181,
    'staging-public' : 3,
    'staging-private' : 182,
    'prod-public' : 1,
    'prod-private' : 180,
    'dev-local': 8086,
    'plasma-test-local': 8087
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
      'dev-local': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["dev-local"]),
          network_id: ids["dev-local"], // Match any network id
          gas: 8000000,
          gasPrice: 5000000000
      },

      'plasma-test-local': {
          provider: () => new HDWalletProvider(mnemonic, rpcs["plasma-test-local"]),
          network_id: ids["plasma-test-local"], // Match any network id
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
          gas: 7800000,
          gasPrice: 200000000000,
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
          gasPrice: 85000000000,
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
                      enabled: false,
                      runs: 200,
                      evmVersion: "byzantium"
                  }
              }
          }
    }

};
