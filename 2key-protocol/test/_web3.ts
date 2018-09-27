import Web3 from 'web3';
import bip39 from 'bip39';
import hdkey from 'ethereumjs-wallet/hdkey';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';

interface EthereumWeb3 {
    web3: any;
    address: string;
}

export default function(mnemonic: string, rpcUrl: string): EthereumWeb3 {
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
  engine.start();
  const web3 = new Web3(engine);
  // web3.eth.defaultBlock = 'pending';
  const address = `0x${wallet.getAddress().toString('hex')}`;
  // web3.eth.defaultAccount = `0x${wallet.getAddress().toString('hex')}`;
  console.log('new Web3', address);
  return { web3, address };
}
