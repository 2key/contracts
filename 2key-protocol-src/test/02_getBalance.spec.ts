import { expect } from 'chai';
import 'mocha';
import { twoKeyProtocol, createTwoKeyInstance } from './_web3';

if (!twoKeyProtocol) {
  createTwoKeyInstance();
}

describe('Get Balance', () => {
  it('should return a balance for address', async () => {
    const balance = await twoKeyProtocol.getBalance();
    expect(balance).to.exist;
    expect(balance).to.haveOwnProperty('balance');
    expect(balance).to.haveOwnProperty('local_address');
    expect(balance).to.haveOwnProperty('gasPrice');
    expect(balance.gasPrice).to.be.equal(twoKeyProtocol.getGasPrice());
  }).timeout(30000);
});

