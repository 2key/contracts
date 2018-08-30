import { expect } from 'chai';
import 'mocha';
import web3 from './_web3';
import TwoKeyProtocol from '../index';
import contractsMeta from '../contracts/meta';

const { env } = process;

const rpcUrl = env.RCP_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;

const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const bonusOffer = 10;
const rate = 1;
const maxCPA = 5;
const openingTime = new Date();
const closingTime = new Date(openingTime.valueOf()).setDate(openingTime.getDate() + 30);
const eventSource = contractsMeta.TwoKeyEventSource.networks[mainNetId].address;
const twoKeyEconomy = contractsMeta.TwoKeyEconomy.networks[mainNetId].address;

console.log(rpcUrl);
console.log(mainNetId);
console.log(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
console.log(contractsMeta.TwoKeyEconomy.networks[mainNetId].address);

let twoKeyProtocol: TwoKeyProtocol;

let order = {
  canTestETHtx: false,
  canTestCampaign: false,
};

function checkOrder(done, step) {
  if (order[step]) {
    done();
  } else {
    setTimeout( function(){ checkOrder(done, step) }, 1000 );
  }
}

describe('TwoKeyProtocol', () => {
  it('should create a 2Key-protocol instance', () => {
    twoKeyProtocol = new TwoKeyProtocol({
      web3,
      networks: {
        mainNetId,
        syncTwoKeyNetId,
      },
    });
    expect(twoKeyProtocol).to.instanceOf(TwoKeyProtocol);
  });
});

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
    console.log('ERC20 Transfer', txHash);
    order.canTestETHtx = true;
  }).timeout(30000);
});

describe('Transfer Ethers', () => {
  console.log(order.canTestETHtx);
  before((done) => {
    checkOrder(done, 'canTestETHtx');
  });

  it('should return estimated gas for transfer ether', async () => {
    const gas = await twoKeyProtocol.getETHTransferGas('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1);
    expect(gas).to.exist;
    expect(gas).to.be.greaterThan(0);
  }).timeout(30000);
  it('should transfer ether', async () => {
    const txHash = await twoKeyProtocol.transferEther('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7', 1, 3000000000);
    expect(txHash).to.exist;
    expect(txHash).to.be.a('string');
    console.log('ETH Transfer', txHash);
    order.canTestCampaign = true;
  }).timeout(30000);
});

// describe('Print Balance', () => {
//   it('should print balances', () => {
//     setTimeout(async () => {
//       const business = await twoKeyProtocol.getBalance();
//       const aydnep = await twoKeyProtocol.getBalance('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7');
//     }, 10000);
//   }).timeout(15000);
// });

describe('TwoKeyCampaign', () => {
  console.log(order.canTestCampaign);
  before((done) => {
    checkOrder(done, 'canTestCampaign');
  });

  it('should calculate gas for campaign contract creation', async () => {
    const gas = await twoKeyProtocol.estimateSaleCampaign({
      eventSource,
      twoKeyEconomy,
      openingTime: openingTime.getTime(),
      closingTime,
      expiryConversion: closingTime,
      bonusOffer,
      rate,
      maxCPA,
    });
    expect(gas).to.exist;
    expect(gas).to.greaterThan(0);
  })
  it('should create a new campaign contract', async () => {
    const campaign = await twoKeyProtocol.createSaleCampaign({
      eventSource,
      twoKeyEconomy,
      openingTime: openingTime.getTime(),
      closingTime,
      expiryConversion: closingTime,
      bonusOffer,
      rate,
      maxCPA,
    }, 15000000000);
    expect(campaign).to.exist;
    expect(campaign).to.haveOwnProperty('address');
    expect(addressRegex.test(campaign.address)).to.be.true;
  }).timeout(600000);
});
