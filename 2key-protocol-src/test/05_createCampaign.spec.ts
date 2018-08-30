import { expect } from 'chai';
import 'mocha';
import { twoKeyProtocol, createTwoKeyInstance } from './_web3';
import TwoKeyProtocol from '..';
import contractsMeta from '../contracts/meta';

if (!twoKeyProtocol) {
  createTwoKeyInstance();
}

const { env } = process;

const mainNetId = env.MAIN_NET_ID;

const addressRegex = /^0x[a-fA-F0-9]{40}$/;

const bonusOffer = 10;
const rate = 1;
const maxCPA = 5;
const openingTime = new Date();
const closingTime = new Date(openingTime.valueOf()).setDate(openingTime.getDate() + 30);
const eventSource = contractsMeta.TwoKeyEventSource.networks[mainNetId].address;
const twoKeyEconomy = contractsMeta.TwoKeyEconomy.networks[mainNetId].address;

describe('TwoKeyCampaign', () => {
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
