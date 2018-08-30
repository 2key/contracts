import { expect } from 'chai';
import 'mocha';
import web3, { createTwoKeyInstance } from './_web3';
import TwoKeyProtocol from '../index';
import contractsMeta from '../contracts/meta';

const { env } = process;

const rpcUrl = env.RCP_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;

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
    createTwoKeyInstance();
  });
});
