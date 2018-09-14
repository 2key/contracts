import Web3 from 'web3';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import FiltersSubprovider from 'web3-provider-engine/subproviders/filters';
import HookedSubprovider from 'web3-provider-engine/subproviders/hooked-wallet';
import ProviderSubprovider from 'web3-provider-engine/subproviders/provider';
import Transaction from 'ethereumjs-tx';


function HDWalletProvider(wallet: any, address: string, provider_url: string, ws?: boolean) {
  this.addresses = [address];
  this.wallets = { [address]: wallet };
  const tmp_accounts = this.addresses;
  const tmp_wallets = this.wallets;
  this.engine = new ProviderEngine();
  console.log('engine created');
  this.engine.addProvider(new HookedSubprovider({
    getAccounts: function(cb) { cb(null, tmp_accounts) },
    getPrivateKey: function(address, cb) {
      if (!tmp_wallets[address]) { return cb('Account not found'); }
      else { cb(null, tmp_wallets[address].getPrivateKey().toString('hex')); }
    },
    signTransaction: function(txParams, cb) {
      let pkey;
      if (tmp_wallets[txParams.from]) { pkey = tmp_wallets[txParams.from].getPrivateKey(); }
      else { cb('Account not found'); }
      var tx = new Transaction(txParams);
      tx.sign(pkey);
      var rawTx = '0x' + tx.serialize().toString('hex');
      cb(null, rawTx);
    }
  }));
  console.log('Hooked added');
  this.engine.addProvider(new FiltersSubprovider());
  console.log('Filter added');
  this.engine.addProvider(new ProviderSubprovider(new Web3.providers.HttpProvider(provider_url)));
  console.log('RPC added', provider_url);
  this.engine.start(); // Required by the provider engine.
  console.log('engine started');
}

HDWalletProvider.prototype.sendAsync = function() {
  this.engine.sendAsync.apply(this.engine, arguments);
};

HDWalletProvider.prototype.send = function() {
  return this.engine.send.apply(this.engine, arguments);
};

// returns the address of the given address_index, first checking the cache
HDWalletProvider.prototype.getAddress = function(idx) {
  console.log('getting addresses', this.addresses[0], idx)
  if (!idx) { return this.addresses[0]; }
  else { return this.addresses[idx]; }
}

// returns the addresses cache
HDWalletProvider.prototype.getAddresses = function() {
  return this.addresses;
}

export default HDWalletProvider;
