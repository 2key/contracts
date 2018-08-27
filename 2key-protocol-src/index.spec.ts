import TwoKeyProtocol from '.';
import { expect } from 'chai';
import 'mocha';
import bip39 from 'bip39';
import hdkey from 'ethereumjs-wallet/hdkey';
import { BalanceMeta } from './interfaces';

const mnemonic = 'laundry version question endless august scatter desert crew memory toy attract cruel';
const aydnepMnemonic = 'bundle insect salad atom alcohol broom frog crumble cigar throw toe alter';

const hdwallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(mnemonic));
const wallet = hdwallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();

const aydnepHDWallet = hdkey.fromMasterSeed(bip39.mnemonicToSeed(aydnepMnemonic));
const aydnepWallet = aydnepHDWallet.derivePath('m/44\'/60\'/0\'/0/' + 0).getWallet();

let twoKeyProtocol: TwoKeyProtocol;
let twoKeyProtocolAydnep: TwoKeyProtocol;

describe('TwoKeyProtocol', () => {
  it('should create a 2Key-protocol instance', () => {
    twoKeyProtocol = new TwoKeyProtocol({
      wallet,
      // wsUrl: 'ws://18.233.2.70:8501',
      // wsUrl: 'ws://192.168.47.100:8546',
      wsUrl: 'ws://localhost:8546',
      networks: {
        mainNetId: 17,
        syncTwoKeyNetId: 47,
      },
    });
    twoKeyProtocolAydnep = new TwoKeyProtocol({
      wallet: aydnepWallet,
      // wsUrl: 'ws://18.233.2.70:8501',
      // wsUrl: 'ws://192.168.47.100:8546',
      wsUrl: 'ws://localhost:8546',
      networks: {
        mainNetId: 17,
        syncTwoKeyNetId: 47,
      },
    });
    expect(twoKeyProtocol).to.instanceOf(TwoKeyProtocol);
    expect(twoKeyProtocolAydnep).to.instanceOf(TwoKeyProtocol);
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
    const gas = await twoKeyProtocol.getERC20TransferGas(twoKeyProtocolAydnep.getAddress(), 1000);
    console.log(gas);
    expect(gas).to.exist;
    expect(gas).to.haveOwnProperty('wei');
    expect(gas.wei).to.be.equal(twoKeyProtocol.getGas());
  }).timeout(30000);
  it('should transfer tokens', async () => {
    console.log(await twoKeyProtocol.getTransaction('0x07230b24628f9bafde23d0196b52f70acf35a258f855e4e08d866d2975934984'));
    const gasLimit = await twoKeyProtocol.getERC20TransferGas(twoKeyProtocolAydnep.getAddress(), 1000);
    const txHash = await twoKeyProtocol.transferTokens(twoKeyProtocolAydnep.getAddress(), 1000, 3000000000);
    // console.log(await twoKeyProtocol.getTransaction(txHash));
    console.log('Transfer Tokens', txHash);
    expect(txHash).to.exist;
    expect(txHash).to.not.null;
  }).timeout(30000);
  it('should return estimated gas for transfer ether', async () => {
    const gas = await twoKeyProtocol.getETHTransferGas(twoKeyProtocolAydnep.getAddress(), 1);
    console.log(gas);
    expect(gas).to.exist;
    expect(gas).to.haveOwnProperty('wei');
    expect(gas.wei).to.be.equal(twoKeyProtocol.getGas());
  }).timeout(30000);
  it('should transfer ether', () => {
    setTimeout(async () => {
      // const gasLimit = await twoKeyProtocol.getETHTransferGas(twoKeyProtocolAydnep.getAddress(), 1);
      const txHash = await twoKeyProtocol.transferEther(twoKeyProtocolAydnep.getAddress(), 1, 3000000000);
      console.log('Transfer Ether', txHash);
      expect(txHash).to.exist;
      expect(txHash).to.not.null;
    }, 5000);
  }).timeout(30000);
  it('should print balances', (done) => {
    setTimeout(async () => {
      const business = await twoKeyProtocol.getBalance();
      const aydnep = await twoKeyProtocolAydnep.getBalance();
      console.log(business);
      console.log(aydnep);
      done();
    }, 10000);
  }).timeout(15000);
});
