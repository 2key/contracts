require('regenerator-runtime/runtime');
require('babel-register');
const Web3 = require('web3');
const TransportNodeJs = require('@ledgerhq/hw-transport-node-hid').default;
const ProviderEngine = require('web3-provider-engine');
const Eth = require('@ledgerhq/hw-app-eth').default;
const ProviderSubprovider = require('web3-provider-engine/subproviders/provider.js');
const FiltersSubprovider = require('web3-provider-engine/subproviders/filters.js');
const createLedgerSubprovider = require('@ledgerhq/web3-subprovider').default;

module.exports = function (rpcUrl, options) {
  const getTransport = async () => {
    const transport = await TransportNodeJs.create();
    transport.setDebugMode(Boolean(process.env.DEBUG));
    return transport;
  };
  const ledger = createLedgerSubprovider(getTransport, options);
  let engine = new ProviderEngine();
  engine.addProvider(ledger);
  engine.addProvider(new FiltersSubprovider());
  engine.addProvider(new ProviderSubprovider(new Web3.providers.HttpProvider(rpcUrl)));
  engine.start();
  // const web3 = new Web3(engine);
  // web3.eth.getAccounts((err, res) => {
  //   console.log('Accounts', err, res);
  // })
  return engine;
}
