import { expect } from 'chai';
import 'mocha';
import { twoKeyProtocol, createTwoKeyInstance } from './_web3';

if (!twoKeyProtocol) {
  createTwoKeyInstance();
}

describe('Transfer ERC20 Tokens', () => {
  it('should return estimated gas for transferTokens', async () => {
    const gas = await twoKeyProtocol.getERC20TransferGas('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1000);
    expect(gas).to.exist;
    expect(gas).to.be.greaterThan(0);
  }).timeout(30000);
  it('should transfer tokens', async () => {
    const txHash = await twoKeyProtocol.transferTokens('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1000, 3000000000);
    expect(txHash).to.exist;
    expect(txHash).to.be.a('string');
    console.log('ERC20 Transfer', Date.now(), txHash);
  }).timeout(30000);
});

