import { expect } from 'chai';
import 'mocha';
import { twoKeyProtocol, createTwoKeyInstance } from './_web3';

if (!twoKeyProtocol) {
  createTwoKeyInstance();
}

describe('Transfer Ethers', () => {
  it('should return estimated gas for transfer ether', async () => {
    const gas = await twoKeyProtocol.getETHTransferGas('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1);
    expect(gas).to.exist;
    expect(gas).to.be.greaterThan(0);
  }).timeout(30000);
  it('should transfer ether', async () => {
    const txHash = await twoKeyProtocol.transferEther('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1, 3000000000);
    expect(txHash).to.exist;
    expect(txHash).to.be.a('string');
    console.log('ETH Transfer', Date.now(),  txHash);
  }).timeout(30000);
});
