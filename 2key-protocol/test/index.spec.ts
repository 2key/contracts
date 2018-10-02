import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol, promisify} from '../src';
import contractsMeta from '../src/contracts';
import createWeb3 from './_web3';

const {env} = process;

// const artifacts = require('../src/contracts.json');
const rpcUrl = env.RCP_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const destinationAddress = env.AYDNEP_ADDRESS;
const delay = env.TEST_DELAY;
// const destinationAddress = env.DESTINATION_ADDRESS || '0xd9ce6800b997a0f26faffc0d74405c841dfc64b7'
console.log(mainNetId);

const addressRegex = /^0x[a-fA-F0-9]{40}$/;
const maxConverterBonusPercent = 23;
const pricePerUnitInETH = 0.1;
const maxReferralRewardPercent = 15;
const moderatorFeePercentage = 1;
const minContributionETH = 1;
const maxContributionETH = 10;
const now = new Date();
const campaignStartTime = Math.round(new Date(now.valueOf()).setDate(now.getDate() - 30) / 1000);
const campaignEndTime = Math.round(new Date(now.valueOf()).setDate(now.getDate() + 30) / 1000);
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
};

// let web3 = createWeb3(mnemonic, rpcUrl);
const web3switcher = {
    deployer: () => createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl),
    aydnep: () => createWeb3(env.MNEMONIC_AYDNEP, rpcUrl, '9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec'),
    gmail: () => createWeb3(env.MNEMONIC_GMAIL, rpcUrl),
    test4: () => createWeb3(env.MNEMONIC_TEST4, rpcUrl),
    renata: () => createWeb3(env.MNEMONIC_RENATA, rpcUrl),
    uport: () => createWeb3(env.MNEMONIC_UPORT, rpcUrl),
    gmail2: () => createWeb3(env.MNEMONIC_GMAIL2, rpcUrl),
    aydnep2: () => createWeb3(env.MNEMONIC_AYDNEP2, rpcUrl),
    test: () => createWeb3(env.MNEMONIC_TEST, rpcUrl),
};
// console.log('MNEMONICS');
// Object.keys(env).filter(key => key.includes('MNEMONIC')).forEach((key) => {
//     console.log(env[key]);
// });

const eventEmited = (error, event) => {
    if (error) {
        console.log('Event error', error);
    } else {
        console.log('2Key Event', event);
    }
};

const addresses = [env.AYDNEP_ADDRESS, env.GMAIL_ADDRESS, env.TEST4_ADDRESS, env.RENATA_ADDRESS, env.UPORT_ADDRESS, env.GMAIL2_ADDRESS, env.AYDNEP2_ADDRESS, env.TEST_ADDRESS];

let twoKeyProtocol: TwoKeyProtocol;

const printBalances = (done) => {
    Promise.all([
        twoKeyProtocol.getBalance(twoKeyAdmin),
        twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS),
        twoKeyProtocol.getBalance(env.GMAIL_ADDRESS),
        twoKeyProtocol.getBalance(env.TEST4_ADDRESS),
        twoKeyProtocol.getBalance(env.RENATA_ADDRESS),
        twoKeyProtocol.getBalance(env.UPORT_ADDRESS),
        twoKeyProtocol.getBalance(env.GMAIL2_ADDRESS),
        twoKeyProtocol.getBalance(env.AYDNEP2_ADDRESS),
        twoKeyProtocol.getBalance(env.TEST_ADDRESS),
    ]).then(([business, aydnep, gmail, test4, renata, uport, gmail2, aydnep2, test]) => {
        console.log('admin balance', twoKeyProtocol.balanceFromWeiString(business, true, true).balance);
        console.log('aydnep balance', twoKeyProtocol.balanceFromWeiString(aydnep, true, true).balance);
        console.log('gmail balance', twoKeyProtocol.balanceFromWeiString(gmail, true, true).balance);
        console.log('test4 balance', twoKeyProtocol.balanceFromWeiString(test4, true, true).balance);
        console.log('renata balance', twoKeyProtocol.balanceFromWeiString(renata, true, true).balance);
        console.log('uport balance', twoKeyProtocol.balanceFromWeiString(uport, true, true).balance);
        console.log('gmail2 balance', twoKeyProtocol.balanceFromWeiString(gmail2, true, true).balance);
        console.log('aydnep2 balance', twoKeyProtocol.balanceFromWeiString(aydnep2, true, true).balance);
        console.log('test balance', twoKeyProtocol.balanceFromWeiString(test, true, true).balance);
        done();
    });
};

describe('TwoKeyProtocol', () => {
    before(function () {
        this.timeout(30000);
        return new Promise(async (resolve, reject) => {
            try {
                const { web3, address } = web3switcher.deployer();
                twoKeyProtocol = new TwoKeyProtocol({
                    web3,
                    address,
                    networks: {
                        mainNetId,
                        syncTwoKeyNetId,
                    },
                });
                const {balance} = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS), true);
                const { balance: adminBalance } = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(), true);
                console.log(adminBalance);
                if (parseFloat(balance['2KEY'].toString()) <= 20000) {
                    console.log('NO BALANCE at aydnep account');
                    const admin = web3.eth.contract(contractsMeta.TwoKeyAdmin.abi).at(contractsMeta.TwoKeyAdmin.networks[mainNetId].address);
                    admin.transfer2KeyTokens(twoKeyEconomy, destinationAddress, twoKeyProtocol.toWei(100000, 'ether'), { from: env.DEPLOYER_ADDRESS },  async (err, res) => {
                        if (err) {
                            reject(err);
                        } else {
                            console.log('Send Tokens', res);
                            const receipt = await twoKeyProtocol.getTransactionReceiptMined(res);
                            resolve(receipt);
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

    let campaignAddress: string;
    let aydnepBalance;
    let txHash;

    it('should return a balance for address', async () => {
        const business = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(twoKeyAdmin), true, true);
        aydnepBalance = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS), true, true);
        const gmail = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.GMAIL_ADDRESS), true, true);
        const test4 = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.TEST4_ADDRESS), true, true);
        const renata = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.RENATA_ADDRESS), true, true);
        const uport = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.UPORT_ADDRESS), true, true);
        const gmail2 = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.GMAIL2_ADDRESS), true, true);
        const aydnep2 = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.AYDNEP2_ADDRESS), true, true);
        const test = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(env.TEST_ADDRESS), true, true);
        console.log('admin balance', business.balance);
        console.log('aydnep balance', aydnepBalance.balance);
        console.log('gmail balance', gmail.balance);
        console.log('test4 balance', test4.balance);
        console.log('renata balance', renata.balance);
        console.log('uport balance', uport.balance);
        console.log('gmail2 balance', gmail2.balance);
        console.log('aydnep2 balance', aydnep2.balance);
        console.log('test balance', test.balance);
        expect(aydnepBalance).to.exist.to.haveOwnProperty('gasPrice')
        // .to.be.equal(twoKeyProtocol.getGasPrice());
    }).timeout(30000);

    it('should save balance to ipfs', () => {
        return twoKeyProtocol.ipfsAdd(aydnepBalance).then((hash) => {
            console.log('IPFS hash', hash);
            expect(hash).to.be.a('string');
        });
    });

    const rnd = Math.floor(Math.random() * 8);
    console.log('Random', rnd, addresses[rnd]);
    const ethDstAddress = addresses[rnd];

    it(`should return estimated gas for transfer ether ${ethDstAddress}`, async () => {
        if (parseInt(mainNetId, 10) > 4) {
            const gas = await twoKeyProtocol.getETHTransferGas(ethDstAddress, twoKeyProtocol.toWei(10, 'ether'));
            console.log('Gas required for ETH transfer', gas);
            expect(gas).to.exist.to.be.greaterThan(0);
        } else {
            expect(true);
        }
    }).timeout(30000);

    it(`should transfer ether to ${ethDstAddress}`, async () => {
        if (parseInt(mainNetId, 10) > 4) {
            // const gasLimit = await twoKeyProtocol.getETHTransferGas(twoKeyProtocolAydnep.getAddress(), 1);
            txHash = await twoKeyProtocol.transferEther(ethDstAddress, twoKeyProtocol.toWei(10, 'ether'), 3000000000);
            console.log('Transfer Ether', txHash, typeof txHash);
            const receipt = await twoKeyProtocol.getTransactionReceiptMined(txHash);
            const status = receipt && receipt.status;
            expect(status).to.be.equal('0x1');
        } else {
            expect(true);
        }
    }).timeout(30000);

    it('should return a balance for address', async () => {
        const { web3, address } = web3switcher.aydnep();
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        const balance = twoKeyProtocol.balanceFromWeiString(await twoKeyProtocol.getBalance(), true);
        console.log('SWITCH USER', balance.balance);
        return expect(balance).to.exist
            .to.haveOwnProperty('gasPrice')
        // .to.be.equal(twoKeyProtocol.getGasPrice());
    }).timeout(30000);

    it('should return estimated gas for transferTokens', async () => {
        const gas = await twoKeyProtocol.getERC20TransferGas(ethDstAddress, twoKeyProtocol.toWei(123, 'ether'));
        console.log('Gas required for Token transfer', gas);
        return expect(gas).to.exist.to.be.greaterThan(0);
    }).timeout(30000);

    it('should transfer tokens', async function () {
        txHash = await twoKeyProtocol.transfer2KEYTokens(ethDstAddress, twoKeyProtocol.toWei(123, 'ether'), 3000000000);
        console.log('Transfer 2Key Tokens', txHash, typeof txHash);
        const receipt = await twoKeyProtocol.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(30000);

    it('should print balances', printBalances).timeout(15000);

    // it('should calculate gas for campaign contract creation', async () => {
    //     const gas = await twoKeyProtocol.estimateAcquisitionCampaign({
    //         campaignStartTime,
    //         campaignEndTime,
    //         expiryConversion: 1000 * 60 * 60 * 24,
    //         maxConverterBonusPercentWei: twoKeyProtocol.toWei(maxConverterBonusPercent, 'ether'),
    //         pricePerUnitInETHWei: twoKeyProtocol.toWei(pricePerUnitInETH, 'ether'),
    //         maxReferralRewardPercentWei: twoKeyProtocol.toWei(maxReferralRewardPercent, 'ether'),
    //         assetContractERC20: twoKeyEconomy,
    //         moderatorFeePercentageWei: twoKeyProtocol.toWei(moderatorFeePercentage, 'ether'),
    //         minContributionETHWei: twoKeyProtocol.toWei(minContributionETH, 'ether'),
    //         maxContributionETHWei: twoKeyProtocol.toWei(maxContributionETH, 'ether'),
    //     });
    //     console.log('TotalGas required for Campaign Creation', gas);
    //     return expect(gas).to.exist.to.greaterThan(0);
    // });

    it('should create a new campaign contract', async () => {
        const campaign = await twoKeyProtocol.createAcquisitionCampaign({
            campaignStartTime,
            campaignEndTime,
            expiryConversion: 1000 * 60 * 60 * 24,
            maxConverterBonusPercentWei: twoKeyProtocol.toWei(maxConverterBonusPercent, 'ether'),
            pricePerUnitInETHWei: twoKeyProtocol.toWei(pricePerUnitInETH, 'ether'),
            maxReferralRewardPercentWei: twoKeyProtocol.toWei(maxReferralRewardPercent, 'ether'),
            assetContractERC20: twoKeyEconomy,
            moderatorFeePercentageWei: twoKeyProtocol.toWei(moderatorFeePercentage, 'ether'),
            minContributionETHWei: twoKeyProtocol.toWei(minContributionETH, 'ether'),
            maxContributionETHWei: twoKeyProtocol.toWei(maxContributionETH, 'ether'),
        }, createCallback, 15000000000);
        console.log('Campaign address', campaign);
        campaignAddress = campaign;
        return expect(addressRegex.test(campaign)).to.be.true;
    }).timeout(1200000);

    // it('should print balance after campaign created', printBalances).timeout(15000);

    it('should transfer assets to campaign', async () => {
        txHash = await twoKeyProtocol.transfer2KEYTokens(campaignAddress, twoKeyProtocol.toWei(1234, 'ether'));
        await twoKeyProtocol.getTransactionReceiptMined(txHash);
        const balance = twoKeyProtocol.fromWei(await twoKeyProtocol.checkAndUpdateAcquisitionInventoryBalance(campaignAddress)).toString();
        console.log('Campaign Balance', balance);
        expect(parseFloat(balance)).to.be.equal(1234);
    }).timeout(300000);

    let refLink;
    it('should create public link for address', async () => {
        try {
            const hash = await twoKeyProtocol.joinAcquisitionCampaign(campaignAddress, -1);
            console.log('1) converter REFLINK:', hash);
            refLink = hash;
            expect(hash).to.be.a('string');
        } catch (err) {
            throw err
        }
    }).timeout(30000);

    it('should get user public link', async () => {
        try {
            const publicLink = await twoKeyProtocol.getAcquisitionPublicLinkKey(campaignAddress);
            console.log('User Public Link', publicLink);
            expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
        } catch (e) {
            throw e;
        }
    }).timeout(10000);

    it('should create a join link', async () => {
        const { web3, address } = web3switcher.gmail();
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        const hash = await twoKeyProtocol.joinAcquisitionCampaign(campaignAddress, 50, refLink);
        console.log('2) gmail offchain REFLINK', hash);
        refLink = hash;
        expect(hash).to.be.a('string');
    }).timeout(30000);

    it('should cut link', async () => {
        const { web3, address } = web3switcher.test4();
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        let maxReward = await twoKeyProtocol.getEstimatedMaximumReferralReward(campaignAddress, refLink);
        console.log(`Estimated maximum referral reward: ${maxReward}%`);
        const hash = await twoKeyProtocol.joinAcquisitionCampaignAndSetPublicLinkWithCut(campaignAddress, refLink, 33);
        refLink = hash;
        console.log('3) test4 Cutted REFLINK', refLink);
        const cut = await twoKeyProtocol.getAcquisitionReferrerCut(campaignAddress);
        console.log('Referrer CUT', env.TEST4_ADDRESS, cut);
        maxReward = await twoKeyProtocol.getEstimatedMaximumReferralReward(campaignAddress, refLink);
        console.log(`Estimated maximum referral reward: ${maxReward}%`);
        expect(hash).to.be.a('string');
    }).timeout(300000);

    // it('should buy some tokens', async () => {
    //     console.log('4) buy from test4 REFLINK', refLink);
    //     const txHash = await twoKeyProtocol.joinAcquisitionCampaignAndConvert(campaignAddress, twoKeyProtocol.toWei(minContributionETH, 'ether'), refLink);
    //     console.log(txHash);
    //     expect(txHash).to.be.a('string');
    // }).timeout(30000);

    it('should joinOffchain after cut', async () => {
        const { web3, address } = web3switcher.renata();
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        const hash = await twoKeyProtocol.joinAcquisitionCampaign(campaignAddress, 20, refLink);
        // const hash = await twoKeyProtocol.joinAcquisitionCampaignAndSetPublicLinkWithCut(campaignAddress, refLink, 1);
        refLink = hash;
        console.log('5) Renata offchain REFLINK', refLink);
        expect(hash).to.be.a('string');
    }).timeout(300000);

    /*
    it('should buy some tokens from uport', async () => {
        const { web3, address } = web3switcher.uport();
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        console.log('6) uport buy from REFLINK', refLink);
        const txHash = await twoKeyProtocol.joinAcquisitionCampaignAndConvert(campaignAddress, twoKeyProtocol.toWei(minContributionETH * 1.5, 'ether'), refLink);
        console.log(txHash);
        expect(txHash).to.be.a('string');
    }).timeout(30000);

    it('should transfer arcs to gmail2', async () => {
        console.log('7) transfer to gmail2 REFLINK', refLink);
        txHash = await twoKeyProtocol.joinAcquisitionCampaignAndShareARC(campaignAddress, refLink, env.GMAIL2_ADDRESS);
        console.log(txHash);
        const receipt = await twoKeyProtocol.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(30000);

    it('should buy some tokens from gmail2', async () => {
        const { web3, address } = web3switcher.gmail2();
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        const arcs = await twoKeyProtocol.getBalanceOfArcs(campaignAddress);
        console.log('GMAIL2 ARCS', arcs);
        txHash = await twoKeyProtocol.transferEther(campaignAddress, twoKeyProtocol.toWei(minContributionETH * 1.1, 'ether'));
        console.log('HASH', txHash);
        await twoKeyProtocol.getTransactionReceiptMined(txHash);
        const conversion = await twoKeyProtocol.getAquisitionConverterConversion(campaignAddress);
        console.log(conversion);
        expect(conversion[2]).to.be.equal(twoKeyProtocol.getAddress());
    }).timeout(30000);

    it('should transfer arcs from new user to test', async () => {
        const { web3, address } = web3switcher.aydnep2();
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        const refReward = await twoKeyProtocol.getEstimatedMaximumReferralReward(campaignAddress, refLink);
        console.log(`Max estimated referral reward: ${refReward}%`);
        txHash = await twoKeyProtocol.joinAcquisitionCampaignAndShareARC(campaignAddress, refLink, env.TEST_ADDRESS);
        console.log(txHash);
        const receipt = await twoKeyProtocol.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(30000);

    it('should buy some tokens from test', async () => {
        const { web3, address } = web3switcher.test();
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            address,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
        });
        txHash = await twoKeyProtocol.transferEther(campaignAddress, twoKeyProtocol.toWei(minContributionETH * 1.1, 'ether'));
        await twoKeyProtocol.getTransactionReceiptMined(txHash);
        const conversion = await twoKeyProtocol.getAquisitionConverterConversion(campaignAddress);
        console.log(conversion);
        expect(conversion[2]).to.be.equal(twoKeyProtocol.getAddress());
    }).timeout(30000);
    */
    it('should print after all tests', printBalances).timeout(15000);
});
