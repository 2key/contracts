import {expect} from 'chai';
import 'mocha';
import { TwoKeyProtocol } from '../src';
import contractsMeta from '../src/contracts';
import createWeb3 from './_web3';

const {env} = process;

const artifacts = require('../src/contracts.json');
const rpcUrl = env.RCP_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const destinationAddress = env.AYDNEP_ADDRESS;
const delay = env.TEST_DELAY;
// const destinationAddress = env.DESTINATION_ADDRESS || '0xd9ce6800b997a0f26faffc0d74405c841dfc64b7'
console.log(mainNetId);

const addressRegex = /^0x[a-fA-F0-9]{40}$/;
const bonusOffer = 23;
const rate = 0.01;
const maxCPA = 15;
const openingTime = new Date();
const closingTime = new Date(openingTime.valueOf()).setDate(openingTime.getDate() + 30);
const eventSource = contractsMeta.TwoKeyEventSource.networks[mainNetId].address;
const twoKeyEconomy = contractsMeta.TwoKeyEconomy.networks[mainNetId].address;
const twoKeyAdmin = contractsMeta.TwoKeyAdmin.networks[mainNetId].address;

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

const createCallback = (name: string, mined: boolean, transactionResult: string): void => {
    console.log(`Contract ${name} ${mined ? `deployed with address ${transactionResult}` : `placed to EVM. Hash ${transactionResult}`}`);
}

// let web3 = createWeb3(mnemonic, rpcUrl);
const web3 = {
    deployer: () => createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl),
    aydnep: () => createWeb3(env.MNEMONIC_AYDNEP, rpcUrl),
    gmail: () => createWeb3(env.MNEMONIC_GMAIL, rpcUrl),
    test4: () => createWeb3(env.MNEMONIC_TEST4, rpcUrl),
};
// console.log('MNEMONICS');
// Object.keys(env).filter(key => key.includes('MNEMONIC')).forEach((key) => {
//     console.log(env[key]);
// });

const addresses = [env.AYDNEP_ADDRESS, env.GMAIL_ADDRESS, env.TEST4_ADDRESS];

let twoKeyProtocol: TwoKeyProtocol;


describe('TwoKeyProtocol', () => {
    before(function () {
        this.timeout(30000);
        return new Promise(async (resolve, reject) => {
            try {
                twoKeyProtocol = new TwoKeyProtocol({
                    web3: web3.deployer(),
                    networks: {
                        mainNetId,
                        syncTwoKeyNetId,
                    },
                });
                const {balance} = await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS);
                if (balance['2KEY'] <= 20000) {
                    console.log('NO BALANCE at aydnep account');
                    const admin = web3.deployer().eth.contract(artifacts.TwoKeyAdmin.abi).at(artifacts.TwoKeyAdmin.networks[mainNetId].address);
                    admin.transfer2KeyTokens(twoKeyEconomy, destinationAddress, twoKeyProtocol.toWei(50000, 'ether'), { from: env.DEPLOYER_ADDRESS, gas: 7000000 },  (err, res) => {
                        if (err) {
                            reject(err);
                        } else {
                            setTimeout(() => {
                                resolve(res);
                            }, 10000);
                        }
                    });
                } else {
                    resolve(balance['2KEY']);
                }
            } catch (err) {
                reject(err);
            }
        })
    });

    beforeEach(function (done) {
        this.timeout((parseInt(delay) || 1000) + 1000);
        // console.log('TwoKeyProtocol.address', twoKeyProtocol.getAddress());
        setTimeout(() => done(), parseInt(delay) || 1000);
    });

    let campaignAddress: string;
    let campaignInventoryAddress: string;

    it('should return a balance for address', async () => {
        const business = await twoKeyProtocol.getBalance(twoKeyAdmin);
        const aydnep = await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS);
        const gmail = await twoKeyProtocol.getBalance(env.GMAIL_ADDRESS);
        const test4 = await twoKeyProtocol.getBalance(env.TEST4_ADDRESS);
        console.log('admin balance', business.balance);
        console.log('aydnep balance', aydnep.balance);
        console.log('gmail balance', gmail.balance);
        console.log('test4 balance', test4.balance);
        console.log(twoKeyProtocol.toWei(1000000, 'ether'));
        return expect(aydnep).to.exist
            .to.haveOwnProperty('gasPrice')
        // .to.be.equal(twoKeyProtocol.getGasPrice());
    }).timeout(30000);

    const rnd = Math.floor(Math.random() * 3);
    console.log('Random', rnd);
    const ethDstAddress = addresses[rnd];

    it(`should return estimated gas for transfer ether ${ethDstAddress}`, async () => {
        if (parseInt(mainNetId, 10) > 4) {
            const gas = await twoKeyProtocol.getETHTransferGas(ethDstAddress, 10);
            console.log('Gas required for ETH transfer', gas);
            expect(gas).to.exist.to.be.greaterThan(0);
        } else {
            expect(true);
        }
    }).timeout(30000);

    it(`should transfer ether to ${ethDstAddress}`, async () => {
        if (parseInt(mainNetId, 10) > 4) {
            // const gasLimit = await twoKeyProtocol.getETHTransferGas(twoKeyProtocolAydnep.getAddress(), 1);
            const txHash = await twoKeyProtocol.transferEther(ethDstAddress, 10, 3000000000);
            console.log('Transfer Ether', txHash, typeof txHash);
            expect(txHash).to.exist.to.be.a('string');
        } else {
            expect(true);
        }
    }).timeout(30000);

    it('should return a balance for address', async () => {
        twoKeyProtocol = new TwoKeyProtocol({
            web3: web3.aydnep(),
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        const balance = await twoKeyProtocol.getBalance();
        console.log('SWITCH USER', balance.balance);
        return expect(balance).to.exist
            .to.haveOwnProperty('gasPrice')
        // .to.be.equal(twoKeyProtocol.getGasPrice());
    }).timeout(30000);

    it('should return estimated gas for transferTokens', async () => {
        const gas = await twoKeyProtocol.getERC20TransferGas(ethDstAddress, 123);
        console.log('Gas required for Token transfer', gas);
        return expect(gas).to.exist.to.be.greaterThan(0);
    }).timeout(30000);

    it('should transfer tokens', async function () {
        const txHash = await twoKeyProtocol.transfer2KEYTokens(ethDstAddress, 123, 3000000000);
        expect(txHash).to.be.a('string');
    }).timeout(30000);

    it('should print balances', (done) => {
        setTimeout(async () => {
            const business = await twoKeyProtocol.getBalance(twoKeyAdmin);
            const aydnep = await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS);
            const gmail = await twoKeyProtocol.getBalance(env.GMAIL_ADDRESS);
            const test4 = await twoKeyProtocol.getBalance(env.TEST4_ADDRESS);
            console.log('admin balance', business.balance);
            console.log('aydnep balance', aydnep.balance);
            console.log('gmail balance', gmail.balance);
            console.log('test4 balance', test4.balance);
            done();
        }, 10000);
    }).timeout(15000);

    it('should calculate gas for campaign contract creation', async () => {
      const gas = await twoKeyProtocol.estimateAcquisitionCampaign({
        eventSource,
        twoKeyEconomy,
        openingTime: openingTime.getTime(),
        closingTime,
        expiryConversion: closingTime,
        bonusOffer,
        rate,
        // rate: twoKeyProtocol.toWei(rate, 'ether'),
        maxCPA,
        erc20address: twoKeyEconomy,
      });
      console.log('TotalGas required for Campaign Creation', gas);
      return expect(gas).to.exist.to.greaterThan(0);
    });

    it('should create a new campaign contract', async () => {
      const campaign = await twoKeyProtocol.createAcquisitionCampaign({
        eventSource,
        twoKeyEconomy,
        openingTime: openingTime.getTime(),
        closingTime,
        expiryConversion: closingTime,
        bonusOffer,
        rate,
        // rate: twoKeyProtocol.toWei(rate, 'ether'),
        maxCPA,
        erc20address: twoKeyEconomy,
      }, createCallback, 15000000000);
      console.log('Campaign address', campaign);
      campaignAddress = campaign;
      return expect(addressRegex.test(campaign)).to.be.true;
    }).timeout(600000);

    it('should print balance after campaign created', (done) => {
        setTimeout(async () => {
            const business = await twoKeyProtocol.getBalance(twoKeyAdmin);
            const aydnep = await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS);
            const gmail = await twoKeyProtocol.getBalance(env.GMAIL_ADDRESS);
            const test4 = await twoKeyProtocol.getBalance(env.TEST4_ADDRESS);
            console.log('admin balance', business.balance);
            console.log('aydnep balance', aydnep.balance);
            console.log('gmail balance', gmail.balance);
            console.log('test4 balance', test4.balance);
            done();
        }, 10000);
    }).timeout(15000);

    it('should transfer assets to campaign', async () => {
      await twoKeyProtocol.transfer2KEYTokens(campaignAddress, 12345);
      const checkBalance = new Promise((resolve, reject) => {
        setTimeout(async () => {
          const res = await twoKeyProtocol.checkAndUpdateFungibleInventory(campaignAddress);
          console.log('Campaign Balance', res);
          resolve(res)
        }, 15000);
        });
        const balance = await checkBalance;
        expect(balance).to.be.equal(12345);
    }).timeout(300000);

    let refLink;
    it('should create public link for address', async () => {
      try {
        const hash = await twoKeyProtocol.joinCampaign(campaignAddress, -1);
        console.log('url:', hash);
        refLink = hash;
        expect(hash).to.be.a('string');
      } catch (err) {
        throw err
      }
    }).timeout(30000);

    it('should get public link for address', async () => {
        try {
            const publicLink = await twoKeyProtocol.getPublicLink(campaignAddress);
            expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
        } catch (e) {
            throw e;
        }
    }).timeout(10000);

    it('should create a join link', async () => {
        twoKeyProtocol = new TwoKeyProtocol({
            web3: web3.gmail(),
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });

        // let hash = refLink;
      // for (let i = 0; i < 1; i++) {
        const hash = await twoKeyProtocol.joinCampaign(campaignAddress, 3, refLink);
        // console.log(i + 1, hash.length);
      // }
      console.log(hash);
      refLink = hash;
      expect(hash).to.be.a('string');
    });

    it('should cut link', async () => {
        twoKeyProtocol = new TwoKeyProtocol({
            web3: web3.test4(),
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        const hash = await twoKeyProtocol.shortUrl(campaignAddress, refLink, 1);
        refLink = hash;
        console.log('Cutted Link', refLink);
        expect(hash).to.be.a('string');
    }).timeout(300000);

    it('should get public link for address', async () => {
        try {
            const publicLink = await twoKeyProtocol.getPublicLink(campaignAddress);
            expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
        } catch (e) {
            throw e;
        }
    }).timeout(10000);

    it('should show influencer cut', async () => {
        const gmailCut = await twoKeyProtocol.getReferrerCut(campaignAddress, env.GMAIL_ADDRESS);
        const test4Cut = await twoKeyProtocol.getReferrerCut(campaignAddress, env.TEST4_ADDRESS);
        console.log('Influencer CUT', env.GMAIL_ADDRESS, gmailCut);
        console.log('Influencer CUT', env.TEST4_ADDRESS, test4Cut);
    }).timeout(15000);

    it('should buy some tokens', async () => {
        const txHash = await twoKeyProtocol.buyCampaignAssetsWithETH(campaignAddress, 0.05, refLink);
        console.log(txHash);
        expect(txHash).to.be.a('string');
    }).timeout(30000);

    it('should print after all tests', (done) => {
        setTimeout(async () => {
            const business = await twoKeyProtocol.getBalance(twoKeyAdmin);
            const aydnep = await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS);
            const gmail = await twoKeyProtocol.getBalance(env.GMAIL_ADDRESS);
            const test4 = await twoKeyProtocol.getBalance(env.TEST4_ADDRESS);
            const res = await twoKeyProtocol.checkAndUpdateFungibleInventory(campaignAddress);
            console.log('Campaign Balance', res);
            console.log('contractor balance', business.balance);
            console.log('aydnep balance', aydnep.balance);
            console.log('gmail balance', gmail.balance);
            console.log('test4 balance', test4.balance);
            done();
        }, 10000);
    }).timeout(15000);
});
