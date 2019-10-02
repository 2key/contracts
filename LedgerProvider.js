require('regenerator-runtime/runtime');
require('babel-register');
const Web3 = require('web3');
const TransportNodeJs = require('@ledgerhq/hw-transport-node-hid').default;
const ProviderEngine = require('web3-provider-engine');
const ProviderSubprovider = require('web3-provider-engine/subproviders/provider');
const NonceSubprovider = require('web3-provider-engine/subproviders/nonce-tracker');
const FiltersSubprovider = require('web3-provider-engine/subproviders/filters');
const createLedgerSubprovider = require('@ledgerhq/web3-subprovider').default;
const DebugSubprovider = require('./DebugProvider');

module.exports = function (rpcUrl, options) {
  const getTransport = () => TransportNodeJs.create();
  const ledger = createLedgerSubprovider(getTransport, options);
  // ledger.signMessage = ledger.signPersonalMessage;
  let engine = new ProviderEngine();
  // engine.addProvider(new DebugSubprovider());
  engine.addProvider(ledger);
  engine.addProvider(new NonceSubprovider());
  engine.addProvider(new FiltersSubprovider());
  engine.addProvider(new ProviderSubprovider(new Web3.providers.HttpProvider(rpcUrl)));
  // engine.send = engine.sendAsync;
  engine.start();
  // const web3 = new Web3(engine);
  // web3.eth.getAccounts((err, res) => {
  //   console.log('Accounts', err, res);
  // })
  return engine;
};
