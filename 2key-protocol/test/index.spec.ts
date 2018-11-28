import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import contractsMeta from '../src/contracts';
import createWeb3 from './_web3';
import Sign from '../src/utils/sign';

const {env} = process;

// const artifacts = require('../src/contracts_deployed.json');
const rpcUrl = env.RPC_URL;
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

const progressCallback = (name: string, mined: boolean, transactionResult: string): void => {
    console.log(`Contract ${name} ${mined ? `deployed with address ${transactionResult}` : `placed to EVM. Hash ${transactionResult}`}`);
};
/*

    "0xb3fa520368f2df7bed4df5185101f303f6c7decc": { "balance": "0x1337000000000000000000" },
    "0xffcf8fdee72ac11b5c542428b35eef5769c409f0": { "balance": "0x1337000000000000000000" },
    "0x22d491bde2303f2f43325b2108d26f1eaba1e32b": { "balance": "0x1337000000000000000000" },
    "0xe11ba2b4d45eaed5996cd0823791e0c93114882d": { "balance": "0x1337000000000000000000" },
    "0xd03ea8624c8c5987235048901fb614fdca89b117": { "balance": "0x1337000000000000000000" },
    "0x95ced938f7991cd0dfcb48f0a06a40fa1af46ebc": { "balance": "0x1337000000000000000000" },
    "0x3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9": { "balance": "0x1337000000000000000000" },
    "0x28a8746e75304c0780e011bed21c72cd78cd535e": { "balance": "0x1337000000000000000000" },
    "0xaca94ef8bd5ffee41947b4585a84bda5a3d3da6e": { "balance": "0x1337000000000000000000" },
    "0x1df62f291b2e969fb0849d99d9ce41e2f137006e": { "balance": "0x1337000000000000000000" },
    "0x610bb1573d1046fcb8a70bbbd395754cd57c2b60": { "balance": "0x1337000000000000000000" },


6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1 0xb3fa520368f2df7bed4df5185101f303f6c7decc
9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec 0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7
6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c 0xffcf8fdee72ac11b5c542428b35eef5769c409f0
646f1ce2fdad0e6deeeb5c7e8e5543bdde65e86029e2fd9fc169899c440a7913 0x22d491bde2303f2f43325b2108d26f1eaba1e32b
add53f9a7e588d003326d1cbf9e4a43c061aadd9bc938c843a79e7b4fd2ad743 0xe11ba2b4d45eaed5996cd0823791e0c93114882d
395df67f0c2d2d9fe1ad08d1bc8b6627011959b79c53d7dd6a3536a33ab8a4fd 0xd03ea8624c8c5987235048901fb614fdca89b117
e485d098507f54e7733a205420dfddbe58db035fa577fc294ebd14db90767a52 0x95ced938f7991cd0dfcb48f0a06a40fa1af46ebc
a453611d9419d0e56f499079478fd72c37b251a94bfde4d19872c44cf65386e3 0x3e5e9111ae8eb78fe1cc3bb8915d5d461f3ef9a9
829e924fdf021ba3dbbc4225edfece9aca04b929d6e75613329ca6f1d31c0bb4 0x28a8746e75304c0780e011bed21c72cd78cd535e

b0057716d5917badaf911b193b12b910811c1497b5bada8d7711f758981c3773 0xaca94ef8bd5ffee41947b4585a84bda5a3d3da6e
77c5495fbb039eed474fc940f29955ed0531693cc9212911efd35dff0373153f 0x1df62f291b2e969fb0849d99d9ce41e2f137006e
*/

// let web3 = createWeb3(mnemonic, rpcUrl);
// const web3switcher = {
//     deployer: () => createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl, '6cbed15c793ce57650b9877cf6fa156fbef513c4e6134f022a85b1ffdd59b2a1'),
//     aydnep: () => createWeb3(env.MNEMONIC_AYDNEP, rpcUrl, '9125720a89c9297cde4a3cfc92f233da5b22f868b44f78171354d4e0f7fe74ec'),
//     gmail: () => createWeb3(env.MNEMONIC_GMAIL, rpcUrl, '6370fd033278c143179d81c5526140625662b8daa446c22ee2d73db3707e620c'),
//     test4: () => createWeb3(env.MNEMONIC_TEST4, rpcUrl, '646f1ce2fdad0e6deeeb5c7e8e5543bdde65e86029e2fd9fc169899c440a7913'),
//     renata: () => createWeb3(env.MNEMONIC_RENATA, rpcUrl, 'add53f9a7e588d003326d1cbf9e4a43c061aadd9bc938c843a79e7b4fd2ad743'),
//     uport: () => createWeb3(env.MNEMONIC_UPORT, rpcUrl, '395df67f0c2d2d9fe1ad08d1bc8b6627011959b79c53d7dd6a3536a33ab8a4fd'),
//     gmail2: () => createWeb3(env.MNEMONIC_GMAIL2, rpcUrl, 'e485d098507f54e7733a205420dfddbe58db035fa577fc294ebd14db90767a52'),
//     aydnep2: () => createWeb3(env.MNEMONIC_AYDNEP2, rpcUrl, 'a453611d9419d0e56f499079478fd72c37b251a94bfde4d19872c44cf65386e3'),
//     test: () => createWeb3(env.MNEMONIC_TEST, rpcUrl, '829e924fdf021ba3dbbc4225edfece9aca04b929d6e75613329ca6f1d31c0bb4'),
// };
const web3switcher = {
    deployer: () => createWeb3(env.MNEMONIC_DEPLOYER, rpcUrl),
    aydnep: () => createWeb3(env.MNEMONIC_AYDNEP, rpcUrl),
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
        console.log('admin balance', twoKeyProtocol.Utils.balanceFromWeiString(business, {
            inWei: true,
            toNum: true
        }).balance);
        console.log('aydnep balance', twoKeyProtocol.Utils.balanceFromWeiString(aydnep, {
            inWei: true,
            toNum: true
        }).balance);
        console.log('gmail balance', twoKeyProtocol.Utils.balanceFromWeiString(gmail, {
            inWei: true,
            toNum: true
        }).balance);
        console.log('test4 balance', twoKeyProtocol.Utils.balanceFromWeiString(test4, {
            inWei: true,
            toNum: true
        }).balance);
        console.log('renata balance', twoKeyProtocol.Utils.balanceFromWeiString(renata, {
            inWei: true,
            toNum: true
        }).balance);
        console.log('uport balance', twoKeyProtocol.Utils.balanceFromWeiString(uport, {
            inWei: true,
            toNum: true
        }).balance);
        console.log('gmail2 balance', twoKeyProtocol.Utils.balanceFromWeiString(gmail2, {
            inWei: true,
            toNum: true
        }).balance);
        console.log('aydnep2 balance', twoKeyProtocol.Utils.balanceFromWeiString(aydnep2, {
            inWei: true,
            toNum: true
        }).balance);
        console.log('test balance', twoKeyProtocol.Utils.balanceFromWeiString(test, {
            inWei: true,
            toNum: true
        }).balance);
        done();
    });
};

describe('TwoKeyProtocol', () => {
    let from: string;
    before(function () {
        this.timeout(30000);
        return new Promise(async (resolve, reject) => {
            try {
                // twoKeyProtocol = new TwoKeyProtocol({
                //     networks: {
                //         mainNetId,
                //         syncTwoKeyNetId,
                //     },
                //     rpcUrl,
                //     plasmaPK: Sign.generatePrivateKey().toString('hex'),
                // });

                const {web3, address} = web3switcher.deployer();
                from = address;
                twoKeyProtocol = new TwoKeyProtocol({
                    web3,
                    networks: {
                        mainNetId,
                        syncTwoKeyNetId,
                    },
                    plasmaPK: Sign.generatePrivateKey().toString('hex'),
                });
                const {balance} = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS), {inWei: true});
                const {balance: adminBalance} = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(contractsMeta.TwoKeyAdmin.networks[mainNetId].address), {inWei: true});
                console.log(adminBalance);
                if (parseFloat(balance['2KEY'].toString()) <= 20000) {
                    console.log('NO BALANCE at aydnep account');
                    const admin = web3.eth.contract(contractsMeta.TwoKeyAdmin.abi).at(contractsMeta.TwoKeyAdmin.networks[mainNetId].address);
                    admin.transfer2KeyTokens(destinationAddress, twoKeyProtocol.Utils.toWei(100000, 'ether'), {from: env.DEPLOYER_ADDRESS}, async (err, res) => {
                        if (err) {
                            reject(err);
                        } else {
                            console.log('Send Tokens', res);
                            console.log("Admin address: " + contractsMeta.TwoKeyAdmin.networks[mainNetId].address);
                            const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(res);
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
        const business = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(twoKeyAdmin), {
            inWei: true,
            toNum: true
        });
        aydnepBalance = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS), {
            inWei: true,
            toNum: true
        });
        const gmail = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.GMAIL_ADDRESS), {
            inWei: true,
            toNum: true
        });
        const test4 = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.TEST4_ADDRESS), {
            inWei: true,
            toNum: true
        });
        const renata = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.RENATA_ADDRESS), {
            inWei: true,
            toNum: true
        });
        const uport = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.UPORT_ADDRESS), {
            inWei: true,
            toNum: true
        });
        const gmail2 = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.GMAIL2_ADDRESS), {
            inWei: true,
            toNum: true
        });
        const aydnep2 = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.AYDNEP2_ADDRESS), {
            inWei: true,
            toNum: true
        });
        const test = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.TEST_ADDRESS), {
            inWei: true,
            toNum: true
        });
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
        return twoKeyProtocol.Utils.ipfsAdd(aydnepBalance).then((hash) => {
            console.log('IPFS hash', hash);
            expect(hash).to.be.a('string');
        });
    }).timeout(30000);

    const rnd = Math.floor(Math.random() * 8);
    console.log('Random', rnd, addresses[rnd]);
    const ethDstAddress = addresses[rnd];

    it(`should return estimated gas for transfer ether ${ethDstAddress}`, async () => {
        if (parseInt(mainNetId, 10) > 4) {
            const gas = await twoKeyProtocol.getETHTransferGas(ethDstAddress, twoKeyProtocol.Utils.toWei(10, 'ether'), from);
            console.log('Gas required for ETH transfer', gas);
            expect(gas).to.exist.to.be.greaterThan(0);
        } else {
            expect(true);
        }
    }).timeout(30000);

    it(`should transfer ether to ${ethDstAddress}`, async () => {
        if (parseInt(mainNetId, 10) > 4) {
            // const gasLimit = await twoKeyProtocol.getETHTransferGas(twoKeyProtocolAydnep.getAddress(), 1);
            txHash = await twoKeyProtocol.transferEther(ethDstAddress, twoKeyProtocol.Utils.toWei(10, 'ether'), from, 3000000000);
            console.log('Transfer Ether', txHash, typeof txHash);
            const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
            const status = receipt && receipt.status;
            expect(status).to.be.equal('0x1');
        } else {
            expect(true);
        }
    }).timeout(30000);

    it('should return a balance for address', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const balance = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(from), {inWei: true});
        console.log('SWITCH USER', balance.balance);
        return expect(balance).to.exist
            .to.haveOwnProperty('gasPrice')
        // .to.be.equal(twoKeyProtocol.getGasPrice());
    }).timeout(30000);

    it('should show token symbol of economy', async () => {
        const tokenSymbol = await twoKeyProtocol.ERC20.getERC20Symbol(twoKeyEconomy);
        console.log(tokenSymbol);
        expect(tokenSymbol).to.be.equal('2KEY');
    }).timeout(10000);

    it('should return estimated gas for transfer2KeyTokens', async () => {
        const gas = await twoKeyProtocol.getERC20TransferGas(ethDstAddress, twoKeyProtocol.Utils.toWei(123, 'ether'), from);
        console.log('Gas required for Token transfer', gas);
        return expect(gas).to.exist.to.be.greaterThan(0);
    }).timeout(30000);

    it('should transfer 2KeyTokens', async function () {
        txHash = await twoKeyProtocol.transfer2KEYTokens(ethDstAddress, twoKeyProtocol.Utils.toWei(123, 'ether'), from, 3000000000);
        console.log('Transfer 2Key Tokens', txHash, typeof txHash);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(30000);

    // it('should print balances', printBalances).timeout(15000);

    // it('should calculate gas for campaign Acquisition Contract creation', async () => {
    //     const gas = await twoKeyProtocol.AcquisitionCampaign.estimateCreation({
    //         campaignStartTime,
    //         campaignEndTime,
    //         expiryConversion: 1000 * 60 * 60 * 24,
    //         maxConverterBonusPercentWei: twoKeyProtocol.toWei(maxConverterBonusPercent, 'ether'),
    //         pricePerUnitInETHWei: twoKeyProtocol.toWei(pricePerUnitInETH, 'ether'),
    //         maxReferralRewardPercentWei: twoKeyProtocol.toWei(c, 'ether'),
    //         assetContractERC20: twoKeyEconomy,
    //         moderatorFeePercentageWei: twoKeyProtocol.toWei(moderatorFeePercentage, 'ether'),
    //         minContributionETHWei: twoKeyProtocol.toWei(minContributionETH, 'ether'),
    //         maxContributionETHWei: twoKeyProtocol.toWei(maxContributionETH, 'ether'),
    //     });
    //     console.log('TotalGas required for Campaign Creation', gas);
    //     return expect(gas).to.exist.to.greaterThan(0);
    // });
    let refLink;
    let campaignData;

    it('should check a user info', async () => {
        const isAddressRegistered = await twoKeyProtocol.Registry.checkIfUserIsRegistered(from, from);
        console.log(`Address ${from} ${isAddressRegistered ? 'REGISTERED' : 'NOT REGISTERED'} in TwoKeyReg`);
        expect(isAddressRegistered).to.true;
    }).timeout(30000);

    it('should create a new campaign Acquisition Contract', async () => {
        campaignData = {
            campaignStartTime,
            campaignEndTime,
            expiryConversion: 1000 * 60 * 60 * 24,
            maxConverterBonusPercentWei: maxConverterBonusPercent,
            pricePerUnitInETHWei: twoKeyProtocol.Utils.toWei(pricePerUnitInETH, 'ether'),
            maxReferralRewardPercentWei: maxReferralRewardPercent,
            assetContractERC20: twoKeyEconomy,
            moderatorFeePercentageWei: moderatorFeePercentage,
            minContributionETHWei: twoKeyProtocol.Utils.toWei(minContributionETH, 'ether'),
            maxContributionETHWei: twoKeyProtocol.Utils.toWei(maxContributionETH, 'ether'),
            currency: 'ETH',
            tokenDistributionDate: 1541109593669,
            maxDistributionDateShiftInDays: 180,
            bonusTokensVestingMonths: 6,
            bonusTokensVestingStartShiftInDaysFromDistributionDate: 180
        };
        const campaign = await twoKeyProtocol.AcquisitionCampaign.create(campaignData, from, {
            progressCallback,
            gasPrice: 150000000000,
            interval: 500,
            timeout: 600000
        });
        console.log('Campaign address', campaign);
        campaignAddress = campaign.campaignAddress;
        refLink = campaign.campaignPublicLinkKey;
        return expect(addressRegex.test(campaignAddress)).to.be.true;
    }).timeout(1200000);

    it('should check for the moderator and contractor in registry after campaign is created', async() => {
        console.log(from);
        const addressesWhereUserIsContractor = await twoKeyProtocol.Registry.getCampaignsWhereUserIsContractor(from);
        const addressesWhereUserIsModerator = await twoKeyProtocol.Registry.getCampaignsWhereUserIsModerator(from);

        console.log("Contractor: " + addressesWhereUserIsContractor);
        console.log("Moderator: " + addressesWhereUserIsModerator);
    }).timeout(30000);


    it('should save campaign to IPFS', async () => {
        const hash = await twoKeyProtocol.Utils.ipfsAdd(campaignData);
        txHash = await twoKeyProtocol.AcquisitionCampaign.updateOrSetIpfsHashPublicMeta(campaignAddress, hash, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const campaignMeta = await twoKeyProtocol.AcquisitionCampaign.getPublicMeta(campaignAddress);
        console.log('IPFS:', hash, campaignMeta);
        expect(campaignMeta.meta.assetContractERC20).to.be.equal(campaignData.assetContractERC20);
    }).timeout(30000);
    // it('should print balance after campaign created', printBalances).timeout(15000);

    it('should transfer assets to campaign', async () => {
        txHash = await twoKeyProtocol.transfer2KEYTokens(campaignAddress, twoKeyProtocol.Utils.toWei(1234, 'ether'), from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const balance = twoKeyProtocol.Utils.fromWei(await twoKeyProtocol.AcquisitionCampaign.checkInventoryBalance(campaignAddress, from)).toString();
        console.log('Campaign Balance', balance);
        expect(parseFloat(balance)).to.be.equal(1234);
    }).timeout(300000);

    // it('should show all users campaigns', async () => {
    //     const campaigns = await twoKeyProtocol.getContractorCampaigns();
    //     console.log(campaigns);
    //     expect(campaigns.length).to.be.greaterThan(0);
    // }).timeout(30000);

    // Implemented in AcquisitionCampaign.create
    // it('should create public link for address', async () => {
    //     try {
    //         const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, -1);
    //         console.log('1) converter REFLINK:', hash);
    //         refLink = hash;
    //         expect(hash).to.be.a('string');
    //     } catch (err) {
    //         throw err
    //     }
    // }).timeout(30000);

    it('should get user public link', async () => {
        try {
            const publicLink = await twoKeyProtocol.AcquisitionCampaign.getPublicLinkKey(campaignAddress, from);
            console.log('User Public Link', publicLink);
            expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
        } catch (e) {
            throw e;
        }
    }).timeout(10000);

    it('should create a join link', async () => {
        const {web3, address} = web3switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        await twoKeyProtocol.AcquisitionCampaign.visit(campaignAddress, refLink);
        console.log('isUserJoined', await twoKeyProtocol.AcquisitionCampaign.isAddressJoined(campaignAddress, from));
        const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, from, {
            cut: 50,
            referralLink: refLink
        });
        console.log('2) gmail offchain REFLINK', hash);
        refLink = hash;
        expect(hash).to.be.a('string');
    }).timeout(30000);

    it('should cut link', async () => {
        await twoKeyProtocol.AcquisitionCampaign.visit(campaignAddress, refLink);
        // twoKeyProtocol.unsubscribe2KeyEvents();
        const {web3, address} = web3switcher.test4();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        console.log('isUserJoined', await twoKeyProtocol.AcquisitionCampaign.isAddressJoined(campaignAddress, from));
        let maxReward = await twoKeyProtocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(campaignAddress, from, refLink);
        console.log(`Estimated maximum referral reward: ${maxReward}%`);
        const hash = await twoKeyProtocol.AcquisitionCampaign.joinAndSetPublicLinkWithCut(campaignAddress, from, refLink, {cut: 33});
        refLink = hash;
        console.log('isUserJoined', await twoKeyProtocol.AcquisitionCampaign.isAddressJoined(campaignAddress, from));
        console.log('3) test4 Cutted REFLINK', refLink);
        const cut = await twoKeyProtocol.AcquisitionCampaign.getReferrerCut(campaignAddress, from);
        console.log('Referrer CUT', env.TEST4_ADDRESS, cut);
        maxReward = await twoKeyProtocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(campaignAddress, from, refLink);
        console.log(`Estimated maximum referral reward: ${maxReward}%`);
        expect(hash).to.be.a('string');
    }).timeout(300000);

    // it('should print amount of tokens that user want to buy', async () => {
    //     const tokens = await twoKeyProtocol.AcquisitionCampaign.getEstimatedTokenAmount(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETH, 'ether'));
    //     console.log(tokens);
    //     expect(tokens.totalTokens).to.gte(0);
    // });

    it('should buy some tokens', async () => {
        console.log('4) buy from test4 REFLINK', refLink);
        const txHash = await twoKeyProtocol.AcquisitionCampaign.joinAndConvert(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETH, 'ether'), refLink, from);
        console.log(txHash);
        // const campaigns = await twoKeyProtocol.getCampaignsWhereConverter(from);
        // console.log(campaigns);
        expect(txHash).to.be.a('string');
    }).timeout(30000);

    it('should joinOffchain after cut', async () => {
        const {web3, address} = web3switcher.renata();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, from, {
            cut: 20,
            referralLink: refLink
        });
        // const hash = await twoKeyProtocol.AcquisitionCampaign.joinAndSetPublicLinkWithCut(campaignAddress, refLink, 1);
        refLink = hash;
        console.log('5) Renata offchain REFLINK', refLink);
        expect(hash).to.be.a('string');
    }).timeout(300000);


    it('should buy some tokens from uport', async () => {
        const {web3, address} = web3switcher.uport();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        console.log('6) uport buy from REFLINK', refLink);
        const txHash = await twoKeyProtocol.AcquisitionCampaign.joinAndConvert(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETH * 1.5, 'ether'), refLink, from);
        console.log(txHash);
        expect(txHash).to.be.a('string');
    }).timeout(30000);

    it('should transfer arcs to gmail2', async () => {
        console.log('7) transfer to gmail2 REFLINK', refLink);
        txHash = await twoKeyProtocol.AcquisitionCampaign.joinAndShareARC(campaignAddress, from, refLink, env.GMAIL2_ADDRESS);
        console.log(txHash);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(30000);

    it('should buy some tokens from gmail2', async () => {
        const {web3, address} = web3switcher.gmail2();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const arcs = await twoKeyProtocol.AcquisitionCampaign.getBalanceOfArcs(campaignAddress, from);
        console.log('GMAIL2 ARCS', arcs);
        txHash = await twoKeyProtocol.transferEther(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETH * 1.1, 'ether'), from);
        console.log('HASH', txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const conversion = await twoKeyProtocol.AcquisitionCampaign.getConverterConversion(campaignAddress, from);
        console.log(conversion);
        expect(conversion[2]).to.be.equal(from);
    }).timeout(30000);

    it('should transfer arcs from new user to test', async () => {
        const {web3, address} = web3switcher.aydnep2();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const refReward = await twoKeyProtocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(campaignAddress, from, refLink);
        console.log(`Max estimated referral reward: ${refReward}%`);
        txHash = await twoKeyProtocol.AcquisitionCampaign.joinAndShareARC(campaignAddress, from, refLink, env.TEST_ADDRESS);
        console.log(txHash);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(30000);

    it('should buy some tokens from test', async () => {
        const {web3, address} = web3switcher.test();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        txHash = await twoKeyProtocol.transferEther(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETH * 1.1, 'ether'), from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const conversion = await twoKeyProtocol.AcquisitionCampaign.getConverterConversion(campaignAddress, from);
        console.log(conversion);
        // expect(lockup).to.exist;
        expect(conversion[2]).to.be.equal(from);
    }).timeout(30000);


    it('should return all pending converters', async () => {
        console.log("Test where we'll fetch all pending converters");
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log(addresses);
    }).timeout(30000);

    it('should return all pending converters from contractor', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });

        const addresses = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log("Addresses: " + addresses);
    }).timeout(30000);


    it('should approve converter', async () => {
        console.log('Test where contractor / moderator can approve converter to execute lockup');
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        txHash = await twoKeyProtocol.AcquisitionCampaign.approveConverter(campaignAddress, env.TEST4_ADDRESS, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const allApproved = await twoKeyProtocol.AcquisitionCampaign.getApprovedConverters(campaignAddress, from);
        console.log('Approved addresses: ', allApproved);

        expect(allApproved[0]).to.be.equal(env.TEST4_ADDRESS);
        const allPendingAfterApproved = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log('All pending after approval: ' + allPendingAfterApproved);
        expect(allPendingAfterApproved.length).to.be.equal(3);
    }).timeout(30000);


    it('should reject converter', async () => {
        console.log("Test where contractor / moderator can reject converter to execute lockup");
        txHash = await twoKeyProtocol.AcquisitionCampaign.rejectConverter(campaignAddress, env.TEST_ADDRESS, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

        const allRejected = await twoKeyProtocol.AcquisitionCampaign.getAllRejectedConverters(campaignAddress, from);
        console.log("Rejected addresses: ", allRejected);

        const allPendingAfterRejected = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log('All pending after rejection: ', allPendingAfterRejected);
        expect(allRejected[0]).to.be.equal(env.TEST_ADDRESS);
        expect(allPendingAfterRejected.length).to.be.equal(2);

    }).timeout(30000);

    it('should cancel converter', async () => {
        const {web3, address} = web3switcher.gmail2();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });

        txHash = await twoKeyProtocol.AcquisitionCampaign.cancelConverter(campaignAddress, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

    }).timeout(30000);

    it('should get all pending converters after cancellation', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });

        const allPending = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log('All pending after cancellation: ', allPending);
        expect(allPending.length).to.be.equal(1);
    }).timeout(30000);

    it('should print campaigns where user converter', async() => {
        const {web3, address} = web3switcher.test4();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        // const campaigns = await twoKeyProtocol.Lockup.getCampaignsWhereConverter(from);
        // console.log(campaigns);
    });


    it('should execute conversion and create lockup contract', async () => {
        const txHash = await twoKeyProtocol.AcquisitionCampaign.executeConversion(campaignAddress, env.TEST4_ADDRESS, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(30000);



    it('should return addresses of lockup contracts for contractor', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        console.log('Lockup contracts addresses : ' + addresses);
        expect(addresses.length).to.be.equal(1);
    }).timeout(30000);
    // it('should print after all tests', printBalances).timeout(15000);

    it('==> should print base tokens balance on lockup contract', async() => {
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        const balance = await twoKeyProtocol.Lockup.getBaseTokensAmount(addresses[0],from);
        console.log("Base balance on lockup contract is : " + balance);
    }).timeout(30000);

    it('==> should print bonus tokens balance on lockup contract', async() => {
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        const balance = await twoKeyProtocol.Lockup.getBonusTokenAmount(addresses[0],from);
        console.log("Bonus balance on lockup contract is: " + balance);
    }).timeout(30000);

    it('==> should print 0 if base tokens are locked otherwise tokens balance', async() => {
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        const balance = await twoKeyProtocol.Lockup.checkIfBaseIsUnlocked(addresses[0],from);
        console.log("Balance is: " + balance);
    }).timeout(30000);

    it('==> should print monthly bonus (vested bonus per month)', async() => {
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        const balance = await twoKeyProtocol.Lockup.getMonthlyBonus(addresses[0],from);
        console.log("Monthly bonus is: " + balance);
    }).timeout(30000);

    it('==> should print how much of tokens are unlocked', async() => {
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        const balance = await twoKeyProtocol.Lockup.getAllUnlockedAtTheMoment(addresses[0],from);
        console.log("Unlocked amount of base & bonus tokens is: " + balance);
    }).timeout(30000);

    it('==> should withdraw available tokens', async() => {
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        const txHash = await twoKeyProtocol.Lockup.withdrawTokens(addresses[0],from);
        console.log(txHash);
    }).timeout(30000);

    it('==> should print amount user has withdrawn', async() => {
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        const balance = await twoKeyProtocol.Lockup.getAmountUserWithdrawn(addresses[0],from);
        console.log("Withdrawn amount of tokens is: " + balance);
    }).timeout(30000);

    it('==> should print statistics of withdrawal', async() => {
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        const stats = await twoKeyProtocol.Lockup.getStatistics(addresses[0], from);
        console.log(stats);
    }).timeout(30000);

    it('should print balances', printBalances).timeout(15000);

    it('==> should contractor withdraw his earnings', async() => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });

        const isContractor:boolean = await twoKeyProtocol.AcquisitionCampaign.isAddressContractor(campaignAddress,from);
        console.log('Aydnep is contractor: ' + isContractor);
        const balanceOfContract = await twoKeyProtocol.getBalance(campaignAddress);
        console.log('contract balance', twoKeyProtocol.Utils.balanceFromWeiString(balanceOfContract, {
            inWei: true,
            toNum: true
        }).balance);

        const contractorBalance = await twoKeyProtocol.AcquisitionCampaign.getContractorBalance(campaignAddress,from);
        console.log('Contractor balance: ' + twoKeyProtocol.Utils.fromWei(contractorBalance));
        const moderatorBalance = await twoKeyProtocol.AcquisitionCampaign.getModeratorBalance(campaignAddress,from);
        console.log('Moderator balance: ' + twoKeyProtocol.Utils.fromWei(moderatorBalance));
        const hash = await twoKeyProtocol.AcquisitionCampaign.contractorWithdraw(campaignAddress,from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
    }).timeout(30000);


    it('==> should print moderator address', async() => {
        const moderatorAddress: string = await twoKeyProtocol.AcquisitionCampaign.getModeratorAddress(campaignAddress,from);
        console.log("Moderator address is: " + moderatorAddress);
    }).timeout(30000);

    it('==> should moderator withdraw his balances in 2key-tokens', async() => {
        const txHash = await twoKeyProtocol.AcquisitionCampaign.moderatorAndReferrerWithdraw(campaignAddress,from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log(txHash);
    }).timeout(30000);

    it('should print balances before cancelation', async() => {
        for (let i = 0; i < addresses.length; i++) {
            let addressCurrent = addresses[i].toString();
            let balance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyEconomy, addressCurrent);
            console.log("Address: " + addressCurrent + " ----- balance: " + balance);
        }
    }).timeout(30000);


    it('should print balances of ERC20 on lockupContracts', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        console.log('Lockup contracts addresses : ' + addresses);
        for (let i = 0; i < addresses.length; i++) {
            let addressCurrent = addresses[i].toString();
            let balance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyEconomy, addressCurrent);
            console.log("Address: " + addressCurrent + " ----- balance: " + balance);
        }
    }).timeout(30000);

    // it('should cancel and return all tokens to acquisition campaign', async () => {
    //     const {web3, address} = web3switcher.aydnep();
    //     from = address;
    //     twoKeyProtocol.setWeb3({
    //         web3,
    //         networks: {
    //             mainNetId,
    //             syncTwoKeyNetId,
    //         },
    //         plasmaPK: Sign.generatePrivateKey().toString('hex'),
    //     });
    //
    //     const txHash = await twoKeyProtocol.AcquisitionCampaign.cancel(campaignAddress, from);
    //     await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    //     // for (let i = 0; i < addresses.length; i++) {
    //     //     let addressCurrent = addresses[i].toString();
    //     //     let balance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyEconomy, addressCurrent);
    //     //     console.log("Address: " + addressCurrent + " ----- balance: " + balance);
    //     // }
    // }).timeout(30000);

    it('should get all whitelisted methods from congress', async () => {
        const methods = await twoKeyProtocol.Congress.getAllowedMethods(from);
        // console.log(methods);
    }).timeout(30000);

    it('should get all whitelisted addresses', async() => {
        const addresses = await twoKeyProtocol.Congress.getAllMembersForCongress(from);
        // console.log(addresses);
        expect(addresses.length).to.be.equal(4);
    }).timeout(30000);

    it('should get rate from upgradable exchange', async() => {
        const rate = await twoKeyProtocol.UpgradableExchange.getRate(from);
        console.log('Rate is : ' + rate);
    }).timeout(30000);

    it('should print currency', async() => {
        const currency = await twoKeyProtocol.AcquisitionCampaign.getAcquisitionCampaignCurrency(campaignAddress, from);
        console.log('Currency is: '+ currency);
    }).timeout(30000);

    it('should print maintainer addresses', async() => {
        const maintainers = await twoKeyProtocol.Registry.getRegistryMaintainers();
        console.log(maintainers);
    }).timeout(30000);

    it('should get moderator total earnings in campaign', async() => {
        const totalEarnings = await twoKeyProtocol.AcquisitionCampaign.getModeratorTotalEarnings(campaignAddress,from);
        console.log('Moderator total earnings: '+ totalEarnings);
    })




    it('should print balances', printBalances).timeout(15000);

    /*

      nationName: string,
    ipfsHashForConstitution: string,
    ipfsHashForDAOPublicInfo: string,
    initialMemberAddresses: string[],
    initialMemberTypes: string[],
    limitsPerMemberType: number[],
     */




    //
    // it('should get all members of DAO', async() => {
    //     const members = await twoKeyProtocol.DecentralizedNation.getAllMembersFromDAO(daoAddress);
    //     console.log('MEMBERS', members);
    // }).timeout(30000);
    //
    //
    // it('should get all members from DAO', async() => {
    //     let members = await twoKeyProtocol.DecentralizedNation.getAllMembersFromDAO(daoAddress);
    //     console.log(members);
    // }).timeout(30000);
});
