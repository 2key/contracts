// Allows us to use ES6 in our migrations and tests.
require('babel-register')
const HDWalletProvider = require('./WalletProvider');
const mnemonic = 'laundry version question endless august scatter desert crew memory toy attract cruel';

module.exports = {
    networks: {
        development: {
            host: 'localhost',
            port: 8545,
            network_id: '*', // Match any network id
            gas: 5141500,
            gasPrice: 2000000000
        },
        'geth-local': {
            provider: () => new HDWalletProvider(mnemonic, 'http://localhost:8545'),
            network_id: '*',
            gas: 7000000,
            gasPrice: 2000000000,
        },
        'rinkeby-infura': {
            provider: () => new HDWalletProvider(mnemonic, 'https://rinkeby.infura.io/6rAARDbMXpJlwODa2kbk'),
            network_id: '*',
            gas: 7000000,
            gasPrice: 2000000000,
        },

        'kovan-infura': {
            provider: function() {
                return new HDWalletProvider(mnemonic, `https://kovan.infura.io/6rAARDbMXpJlwODa2kbk`);
            },
            network_id: '42',
            gasPrice: 2000000000
        }
    }
}

