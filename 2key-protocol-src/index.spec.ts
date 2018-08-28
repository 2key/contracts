import { expect } from 'chai';
import 'mocha';
import Web3 from 'web3';
import bip39 from 'bip39';
import hdkey from 'ethereumjs-wallet/hdkey';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import TwoKeyProtocol from '.';
import { CreateCampaign } from './interfaces';

const mnemonic = 'laundry version question endless august scatter desert crew memory toy attract cruel';
const aydnepMnemonic = 'bundle insect salad atom alcohol broom frog crumble cigar throw toe alter';

const hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(mnemonic));
const wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();

// const aydnepHDWallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(aydnepMnemonic));
// const aydnepWallet = aydnepHDWallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();

const engine = new ProviderEngine();
// const mainProvider = new WSSubprovider({ rpcUrl: 'ws://18.233.2.70:8501' })
const mainProvider = new WSSubprovider({ rpcUrl: 'ws://localhost:8546' })
engine.addProvider(new WalletSubprovider(wallet, {}));
engine.addProvider(mainProvider);

// this.web3 = new Web3(new HDWalletProvider(wallet, address, rpcUrl));
const web3 = new Web3(engine);
engine.start();
web3.eth.defaultBlock = 'pending';
web3.eth.defaultAccount = `0x${wallet.getAddress().toString('hex')}`;


let twoKeyProtocol: TwoKeyProtocol;

describe('TwoKeyProtocol', () => {
  it('should create a 2Key-protocol instance', () => {
    twoKeyProtocol = new TwoKeyProtocol({
      web3,
      networks: {
        mainNetId: 17,
        syncTwoKeyNetId: 47,
      },
    });
    expect(twoKeyProtocol).to.instanceOf(TwoKeyProtocol);
  });
  it('should return a balance for address', async () => {
    const balance = await twoKeyProtocol.getBalance();
    console.log(balance);
    expect(balance).to.exist;
    expect(balance).to.haveOwnProperty('balance');
    expect(balance).to.haveOwnProperty('local_address');
    expect(balance).to.haveOwnProperty('gasPrice');
    expect(balance.gasPrice).to.be.equal(twoKeyProtocol.getGasPrice());
    // expect(balance).to.haveOwnProperty('gasPrice1');
  }).timeout(30000);
  it('should return estimated gas for transferTokens', async () => {
    const gas = await twoKeyProtocol.getERC20TransferGas('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1000);
    console.log(gas);
    expect(gas).to.exist;
    expect(gas).to.haveOwnProperty('wei');
    expect(gas.wei).to.be.equal(twoKeyProtocol.getGas());
  }).timeout(30000);
  it('should transfer tokens', async () => {
    console.log(await twoKeyProtocol.getTransaction('0x07230b24628f9bafde23d0196b52f70acf35a258f855e4e08d866d2975934984'));
    // const gasLimit = await twoKeyProtocol.getERC20TransferGas(twoKeyProtocolAydnep.getAddress(), 1000);
    const txHash = await twoKeyProtocol.transferTokens('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1000, 3000000000);
    // console.log(await twoKeyProtocol.getTransaction(txHash));
    console.log('Transfer Tokens', txHash);
    expect(txHash).to.exist;
    expect(txHash).to.not.null;
  }).timeout(30000);
  it('should return estimated gas for transfer ether', async () => {
    const gas = await twoKeyProtocol.getETHTransferGas('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1);
    console.log(gas);
    expect(gas).to.exist;
    expect(gas).to.haveOwnProperty('wei');
    expect(gas.wei).to.be.equal(twoKeyProtocol.getGas());
  }).timeout(30000);
  it('should transfer ether', () => {
    setTimeout(async () => {
      // const gasLimit = await twoKeyProtocol.getETHTransferGas(twoKeyProtocolAydnep.getAddress(), 1);
      const txHash = await twoKeyProtocol.transferEther('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1, 3000000000);
      console.log('Transfer Ether', txHash);
      expect(txHash).to.exist;
      expect(txHash).to.not.null;
    }, 5000);
  }).timeout(30000);
  it('should print balances', (done) => {
    setTimeout(async () => {
      const business = await twoKeyProtocol.getBalance();
      const aydnep = await twoKeyProtocol.getBalance('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7');
      console.log(business);
      console.log(aydnep);
      done();
    }, 10000);
  }).timeout(15000);
  it('should create a new campaign contract', async (done) => {
    const campaign = await twoKeyProtocol.createSaleCampaign({
      eventSource: '0x835aaf6ea6b04892915a8299110652e7cc897a4e',
      twoKeyEconomy: '0x9993da88b6721bc0844e5c5b1ea02d25c38b2c12',
    });
    done();
  }).timeout(600000);
});
