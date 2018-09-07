import { expect } from 'chai';
import 'mocha';
import Web3 from 'web3';
import bip39 from 'bip39';
import hdkey from 'ethereumjs-wallet/hdkey';
import ProviderEngine from 'web3-provider-engine';
import RpcSubprovider from 'web3-provider-engine/subproviders/rpc';
import WSSubprovider from 'web3-provider-engine/subproviders/websocket';
import WalletSubprovider from 'ethereumjs-wallet/provider-engine';
import TwoKeyProtocol from '../index';
import contractsMeta from '../contracts/meta';
import createWeb3 from './_web3';

const { env } = process;

const mnemonic = env.MNEMONIC;
const rpcUrl = env.RCP_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const destinationAddress = env.DESTINATION_ADDRESS;
const delay = env.TEST_DELAY;
// const destinationAddress = env.DESTINATION_ADDRESS || '0xd9ce6800b997a0f26faffc0d74405c841dfc64b7'

const addressRegex = /^0x[a-fA-F0-9]{40}$/;
const bonusOffer = 10;
const rate = 1;
const maxCPA = 5;
const openingTime = new Date();
const closingTime = new Date(openingTime.valueOf()).setDate(openingTime.getDate() + 30);
const eventSource = contractsMeta.TwoKeyEventSource.networks[mainNetId].address;
const twoKeyEconomy = contractsMeta.TwoKeyEconomy.networks[mainNetId].address;

function makeHandle(max: number = 8): string {
  let text = '';
  let possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  for (let i = 0; i < max; i++)
    text += possible.charAt(Math.floor(Math.random() * possible.length));

  return text;
}

// console.log(makeHandle(4096));

console.log(rpcUrl);
console.log(mainNetId);
console.log(contractsMeta.TwoKeyEventSource.networks[mainNetId].address);
console.log(contractsMeta.TwoKeyEconomy.networks[mainNetId].address);

let web3 = createWeb3(mnemonic, rpcUrl);
// const dstWeb3 = createWeb3(env.MNEMONIC_DST, rpcUrl);

let twoKeyProtocol: TwoKeyProtocol;


describe('TwoKeyProtocol', () => {
  beforeEach(function (done) {
    this.timeout((parseInt(delay) || 1000) + 1000);
    setTimeout(() => done(), parseInt(delay) || 1000);
  });
  let campaignAddress: string;
  let campaignInventoryAddress: string;
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
  it('should return a balance for address', async () => {
    const balance = await twoKeyProtocol.getBalance();
    console.log('Balance', balance);
    return expect(balance).to.exist
      // .to.haveOwnProperty('local_address')
      .to.haveOwnProperty('gasPrice')
      // .to.haveOwnProperty('balance')
      .to.be.equal(twoKeyProtocol.getGasPrice());
    // expect(balance).to.haveOwnProperty('gasPrice1');
  }).timeout(30000);
  it('should return estimated gas for transferTokens', async () => {
    const gas = await twoKeyProtocol.getERC20TransferGas(destinationAddress, 1000);
    console.log('Gas required for Token transfer', gas);
    return expect(gas).to.exist.to.be.greaterThan(0);
  }).timeout(30000);
  it('should transfer tokens', async () => {
    // console.log(await twoKeyProtocol.getTransaction('0x07230b24628f9bafde23d0196b52f70acf35a258f855e4e08d866d2975934984'));
    // const gasLimit = await twoKeyProtocol.getERC20TransferGas(twoKeyProtocolAydnep.getAddress(), 1000);
    const txHash = await twoKeyProtocol.transferTokens(destinationAddress, 1000, 3000000000);
    // console.log(await twoKeyProtocol.getTransaction(txHash));
    console.log('Transfer Tokens', txHash);
    return expect(txHash).to.exist.to.be.a('string');
  }).timeout(30000);
  it('should return estimated gas for transfer ether', async () => {
    const gas = await twoKeyProtocol.getETHTransferGas(destinationAddress, 1);
    console.log('Gas required for ETH transfer', gas);
    return expect(gas).to.exist.to.be.greaterThan(0);
  }).timeout(30000);
  it('should transfer ether', () => {
    setTimeout(async () => {
      // const gasLimit = await twoKeyProtocol.getETHTransferGas(twoKeyProtocolAydnep.getAddress(), 1);
      const txHash = await twoKeyProtocol.transferEther(destinationAddress, 1, 3000000000);
      console.log('Transfer Ether', txHash, typeof txHash);
      return expect(txHash).to.exist.to.be.a('string');
    }, 5000);
  }).timeout(30000);
  it('should print balances', (done) => {
    setTimeout(async () => {
      const business = await twoKeyProtocol.getBalance();
      const aydnep = await twoKeyProtocol.getBalance(destinationAddress);
      console.log('BUSINESS balance', business);
      console.log('DESTINATION balance', aydnep);
      done();
    }, 10000);
  }).timeout(15000);
  // const rndHandle = makeHandle();
  // it('should update handle', async () => {
  //   web3 = createWeb3(env.MNEMONIC_DST, rpcUrl);
  //   twoKeyProtocol = new TwoKeyProtocol({
  //     web3,
  //     networks: {
  //       mainNetId,
  //       syncTwoKeyNetId,
  //     },
  //   });
  //   const txHash = await twoKeyProtocol.setHandle(rndHandle);
  //   expect(txHash).to.be.a('string');
  // }).timeout(30000);
  // it('should check address handle', async () => {
  //   const handle = await twoKeyProtocol.getAddressHandle(rndHandle);
  //   console.log('Handle', handle);
  //   expect(handle).to.be.equal(rndHandle);
  // });
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
    console.log('TotalGas required', gas);
    return expect(gas).to.exist.to.greaterThan(0);
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
    console.log('Campaign address', campaign);
    campaignAddress = campaign;
    // return expect(campaign[0]).to.exist.to.haveOwnProperty('address');
    return expect(addressRegex.test(campaign)).to.be.true;
    // const userCampaigns = await twoKeyProtocol.getContractorCampaigns();
    // console.log('User Campaigns', userCampaigns);
  }).timeout(600000);
  it('should set ERC20 address', async () => {
    const address = await twoKeyProtocol.addAssetContractERC20(campaignAddress, twoKeyEconomy);
    expect(address).to.be.equal(twoKeyEconomy);
  }).timeout(30000);
  it('should get ERC20 address', async () => {
    const address = await twoKeyProtocol.getAssetContractAddress(campaignAddress);
    expect(address).to.be.equal(twoKeyEconomy);
  }).timeout(30000);
  let fMessage;
  it('should create public link for address', async () => {
    try {
      const hash = await twoKeyProtocol.joinCampaign(campaignAddress, 0);
      console.log('IPFS:', hash);
      fMessage = hash;
      expect(hash).to.be.a('string');
    } catch (err) {
      throw err
    }
  }).timeout(30000);
  it('should create a join link', async () => {
    // const hash = await twoKeyProtocol.joinCampaign(campaignAddress, 0, fMessage);
    let hash = fMessage;
    for (let i = 0; i < 20; i++) {
      hash = await twoKeyProtocol.joinCampaign(campaignAddress, 0, hash);
      console.log(i + 1, hash.length);
    }
    console.log(hash);
    console.log(hash.length);
    expect(hash).to.be.a('string');
  });
  // it('should add inventory to contract', async () => {
  //   const txHash = await twoKeyProtocol.addFungibleInventory(campaignInventoryAddress, twoKeyEconomy, 1234);
  //   console.log('Add Inventory:', txHash);
  //   return expect(txHash).to.be.a('string');
  // }).timeout(30000);
  // it('should print inventory', (done) => {
  //   setTimeout(async () => {
  //     const inventory = await twoKeyProtocol.getFungibleInventory(twoKeyEconomy, campaignInventoryAddress);
  //     console.log('Inventory', inventory);
  //     const campaigns = await twoKeyProtocol.getContractorCampaigns();
  //     console.log('Canpaigns', campaigns);
  //     done();
  //   }, 15000);
  // }).timeout(32000);
});