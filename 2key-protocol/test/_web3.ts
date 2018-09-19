import Web3 from 'web3';
import bip39 from 'bip39';
import hdkey from 'ethereumjs-wallet/hdkey';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
// import TwoKeyProtocol from '../index';

// const { env } = process;

// const mnemonic = env.MNEMONIC;
// const rpcUrl = env.RCP_URL;
// const mainNetId = env.MAIN_NET_ID;
// const syncTwoKeyNetId = env.SYNC_NET_ID;

export default function(mnemonic, rpcUrl): any {
  const hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(mnemonic));
  const wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();

  // const aydnepHDWallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(aydnepMnemonic));
  // const aydnepWallet = aydnepHDWallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();

  const engine = new ProviderEngine();
  // const mainProvider = new WSSubprovider({ rpcUrl: 'ws://18.233.2.70:8501' })
  const mainProvider = rpcUrl.startsWith('http') ? new RpcSubprovider({ rpcUrl }) : new WSSubprovider({ rpcUrl });
  engine.addProvider(new WalletSubprovider(wallet, {}));
  engine.addProvider(mainProvider);

  // this.web3 = new Web3(new HDWalletProvider(wallet, address, rpcUrl));
  const web3 = new Web3(engine);
  engine.start();
  web3.eth.defaultBlock = 'pending';
  web3.eth.defaultAccount = `0x${wallet.getAddress().toString('hex')}`;
  console.log('new Web3', web3.eth.defaultAccount);
  return web3;
}
