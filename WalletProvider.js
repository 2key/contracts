const bip39 = require('bip39');
const hdkey = require('ethereumjs-wallet/hdkey');
const ProviderEngine = require('web3-provider-engine');
const WalletSubprovider = require('ethereumjs-wallet/provider-engine');
const RpcSubprovider = require('web3-provider-engine/subproviders/rpc');
const WSSubprovider = require('web3-provider-engine/subproviders/websocket');

function WalletProvider(mnemonic, rpcUrl, websocket) {
  const hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(mnemonic));
  /* eslint-disable prefer-template */
  const wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();
  /* eslint-enable prefer-template */
  const engine = new ProviderEngine();
  engine.addProvider(new WalletSubprovider(wallet, {}));
  // console.log('Added wallet');
  engine.addProvider(websocket ? new WSSubprovider({ rpcUrl }) : new RpcSubprovider({ rpcUrl }));
  // console.log('Added provider', websocket ? `WS-${rpcUrl}` : `RPC-${rpcUrl}`);
  engine.start();
  return engine;
}

module.exports = WalletProvider;
