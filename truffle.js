// Allows us to use ES6 in our migrations and tests.
require('babel-register');
// https://github.com/trufflesuite/truffle-hdwallet-provider
const HDWalletProvider = require('truffle-hdwallet-provider');
const PrivateKeyProvider = require('truffle-privatekey-provider');
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

/*
# Internal
## Testing:
Private: geth.private.test.k8s.2key.net:8545, geth.private.test.k8s.2key.net:8546
Public: geth.public.test.k8s.2key.net:8545, geth.public.test.k8s.2key.net:8546

## Production:
Private: geth.private.prod.k8s.2key.net:8545, geth.private.prod.k8s.2key.net:8546
Public: geth.public.prod.k8s.2key.net:8545, geth.public.prod.k8s.2key.net:8546

# External:
## Testing:
Private: ext.geth.private.test.k8s.2key.net:8545, ext.geth.private.test.k8s.2key.net:8546
Private WS SSL: ws-ext.geth.private.test.k8s.2key.net:443

Public: ext.geth.public.test.k8s.2key.net:8545, ext.geth.public.test.k8s.2key.net:8546
Public WS SSL: ws-ext.geth.public.test.k8s.2key.net:443

## Production:
Private: ext.geth.private.prod.k8s.2key.net:8545, ext.geth.private.prod.k8s.2key.net:8546
Public: ext.geth.public.prod.k8s.2key.net:8545, ext.geth.public.prod.k8s.2key.net:8546

*/

module.exports = {
  networks: {
    'dev-local': {
      provider: new HDWalletProvider(mnemonic, 'http://localhost:8545'),
      network_id: 8086, // Match any network id
      gas: 8000000,
      gasPrice: 2000000000
    },

    'development' : {
        host: "localhost",
        port: 8545,
        network_id: "*" // Match any network id
    },

    'rinkeby' : {
      provider: () => LedgerProvider(`https://rinkeby.infura.io/v3/${infuraApiKey}`, {
        networkId: 4,
        // https://github.com/LedgerHQ/ledgerjs/issues/200
        path: "44'/60'/0'/0",
        askConfirm: true,
        accountsLength: 1,
        accountsOffset: 0,
      }),
      network_id: 4,
      gas: 7000000,
      gasPrice: 50000000000,
    },

    'public.test.k8s' : {
      provider: () => LedgerProvider('https://rpc.public.test.k8s.2key.net', {
        networkId: 4,
        // https://github.com/LedgerHQ/ledgerjs/issues/200
        path: "44'/60'/0'/0",
        // askConfirm: true,
        askConfirm: false,
        accountsLength: 1,
        accountsOffset: 0,
      }),
      network_id: 4,
      gas: 7000000,
      gasPrice: 50000000000,
    },

    'private.test.k8s': {
      // 0x0E0D3E393B47058c3A85e33EFE542B7fBc51BB07
      // http://ext.geth.private.test.k8s.2key.net:8545/
      // provider: () => new PrivateKeyProvider('da16b3f97e1f39ac93788d925e17286f20dc737cc208d57ca4d49b128b69eb85', 'http://ext.geth.private.test.k8s.2key.net:8545'),
      provider: () => new HDWalletProvider(mnemonic, 'https://rpc.private.test.k8s.2key.net'),
      // host: 'https://ext.geth.private.test.k8s.2key.net',
      // port: 8545,
      // network_id: 98052, // Match any network id
      network_id: 98052,
      gas: 7000000,
      gasPrice: 0,
      // gasPrice: 100000000000,
      // gasPrice: 2000000000
    },


    'rinkeby-test' : {
        provider: () => new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/v3/904c762bd6984606bf8ae7f30d7cb28c'),
        network_id: 4,
        gas: 7000000,
        gasPrice: 50000000000
    },

    'staging' : {
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

    'ropsten' : {
        provider: () => new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/v3/71d39c30bc984e8a8a0d8adca84620ad'),
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

    'plasma-dev': {
      // host: '107.23.249.140',
      // port: 8090,
      provider: () => new HDWalletProvider(mnemonic, 'https://test.plasma.2key.network/'),
      network_id: 17, // Match any network id
      gas: 7000000,
      gasPrice: 0,
      // gasPrice: 2000000000
    },
  }
};
