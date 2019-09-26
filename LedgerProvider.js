require('regenerator-runtime/runtime');
require('babel-register');
const Web3 = require('web3');
const TransportNodeJs = require('@ledgerhq/hw-transport-node-hid').default;
const ProviderEngine = require('web3-provider-engine');
const ProviderSubprovider = require('web3-provider-engine/subproviders/provider.js');
const createLedgerSubprovider = require('@ledgerhq/web3-subprovider').default;

module.exports = function (rpcUrl, options) {
  const getTransport = () => TransportNodeJs.create();
  const ledger = createLedgerSubprovider(getTransport, options);
  let engine = new ProviderEngine();
  engine.addProvider(ledger);
  engine.addProvider(new ProviderSubprovider(new Web3.providers.HttpProvider(rpcUrl)));
  engine.start();
  // const web3 = new Web3(engine);
  // web3.eth.getAccounts((err, res) => {
  //   console.log('Accounts', err, res);
  // })
  return engine;
};
