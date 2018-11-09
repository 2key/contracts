import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import contractsMeta from '../src/contracts';
import createWeb3 from './_web3';
import Sign from '../src/utils/sign';
import {INationalVotingCampaign} from "../src/decentralizedNation/interfaces";

const {env} = process;

// const artifacts = require('../src/contracts.json');
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
let referralLink;

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
                    admin.transfer2KeyTokens(twoKeyEconomy, destinationAddress, twoKeyProtocol.Utils.toWei(100000, 'ether'), {from: env.DEPLOYER_ADDRESS}, async (err, res) => {
                        if (err) {
                            reject(err);
                        } else {
                            console.log('Send Tokens', res);
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

    const rnd = Math.floor(Math.random() * 8);
    console.log('Random', rnd, addresses[rnd]);


    it('should check if address is maintainer', async() => {
        let isMaintainer = await twoKeyProtocol.DecentralizedNation.check(from, from);
        console.log(isMaintainer);
    }).timeout(30000);


    let daoAddress;
    it('should create new Decentralized nation', async() => {
        const DAOdata = {
            nationName: "Liberland",
            ipfsHashForConstitution: "0x1234",
            ipfsHashForDAOPublicInfo: "0x1234",
            initialMemberAddresses: ['0xb3fa520368f2df7bed4df5185101f303f6c7decc',
                '0xffcf8fdee72ac11b5c542428b35eef5769c409f0',],
            initialMemberTypes:['PRESIDENT', 'MINISTER'],
            eligibleToStartVotingCampaign: [1,1],
            minimalNumberOfVotersForVotingCampaign: 100000,
            minimalPercentOfVotersForVotingCampaign: 60,
            minimalNumberOfVotersForPetitioningCampaign: 1000000,
            minimalPercentOfVotersForPetitioningCampaign: 51,
            limitsPerMemberType: [15,15]
        };

        daoAddress = await twoKeyProtocol.DecentralizedNation.create(DAOdata, from);
        console.log(daoAddress);
    }).timeout(30000);

    // it('should get all members of DAO', async() => {
    //     const members = await twoKeyProtocol.DecentralizedNation.getAllMembersForSpecificType(daoAddress, from);
    //     console.log('MEMBERS', members);
    // }).timeout(30000);


    // it('should get all members from DAO', async() => {
    //     let members = await twoKeyProtocol.DecentralizedNation.getAllMembersFromDAO(daoAddress);
    //     console.log(members);
    // }).timeout(30000);


    // it('should add members by founder', async() => {
    //     let newmember = '0xffcf8fdee72ac11b5c542428b35eef5769c409f0';
    //     let memberType = 'PRESIDENT';
    //     let txHash = await twoKeyProtocol.DecentralizedNation.addMemberByFounder(daoAddress,newmember, memberType, from);
    //     await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    // }).timeout(30000);

    // it('should add members by founder', async() => {
    //     // let newmember = '0xb3fa520368f2df7bed4df5185101f303f6c7decc';
    //     let memberType = 'PRESIDENT';
    //     const members = [
    //         '0xb3fa520368f2df7bed4df5185101f303f6c7decc',
    //         '0xffcf8fdee72ac11b5c542428b35eef5769c409f0',
    //         '0x22d491bde2303f2f43325b2108d26f1eaba1e32b',
    //         '0xf3c7641096bc9dc50d94c572bb455e56efc85412',
    //         '0xebadf86c387fe3a4378738dba140da6ce014e974',
    //         '0xec8b6aaee825e0bbc812ca13e1b4f4b038154688',
    //         '0xfc279a3c3fa62b8c840abaa082cd6b4073e699c8',
    //         '0xc744f2ddbca85a82be8f36c159be548022281c62',
    //         '0x1b00334784ee0360ddf70dfd3a2c53ccf51e5b96',
    //         '0x084d61962273589bf894c7b8794aa8915a06200f'
    //     ];
    //     const l = members.length;
    //     for (let i = 0; i < l; i++) {
    //         const txHash = await twoKeyProtocol.DecentralizedNation.addMemberByFounder(daoAddress, members[i], memberType, from);
    //         await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    //     }
    //     // let txHash = await twoKeyProtocol.DecentralizedNation.addMemberByFounder(daoAddress,newmember, memberType, from);
    //     // await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    // }).timeout(300000);
    //
    // it('should add members by founder', async() => {
    //     let newmember = '0x22d491bde2303f2f43325b2108d26f1eaba1e32b';
    //     let memberType = 'PRESIDENT';
    //     let txHash = await twoKeyProtocol.DecentralizedNation.addMemberByFounder(daoAddress,newmember, memberType, from);
    //     await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    // }).timeout(30000);

    // it('should get all members from DAO', async() => {
    //     let members = await twoKeyProtocol.DecentralizedNation.getAllMembersFromDAO(daoAddress);
    //     console.log(members);
    // }).timeout(30000);
    //

    // NVC = National Voting Campaign which executes itself when voting is finished
    it('should create  new  Campaign', async() => {
        const campaign : INationalVotingCampaign= {
            votingReason: 'Because Andrii is not good CSS dev :D',
            campaignLengthInDays: 1,
            flag: 0,
        };
        referralLink = await twoKeyProtocol.DecentralizedNation.createCampaign(daoAddress,campaign,from);
        console.log('VOTE PUBLIC LINK', referralLink);
    }).timeout(30000);

    let votingCampaign;
    it('get all voting campaigns for DAO', async() => {
        let campaigns = await twoKeyProtocol.DecentralizedNation.getAllCampaigns(daoAddress);
        console.log(campaigns);
        votingCampaign = campaigns[0].votingCampaignContractAddress;
    }).timeout(30000);

    it('it should check role for create voting', async() => {
        let isAbleToStartVoting = await twoKeyProtocol.DecentralizedNation.isTypeEligibleToCreateAVotingCampaign(daoAddress, 'PRESIDENT');
        console.log(isAbleToStartVoting);
    }).timeout(30000);

    it('should join link from gmail', async() => {
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
        referralLink = await twoKeyProtocol.DecentralizedNation.join(votingCampaign, from, { cut: 50, referralLink });
        console.log('GMAIL LINK', referralLink);
    }).timeout(30000);

    it('should join link from test4', async() => {
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
        referralLink = await twoKeyProtocol.DecentralizedNation.join(votingCampaign, from, { cut: 100, referralLink });
        console.log('TEST4 LINK', referralLink);
    }).timeout(30000);

    it('should calculate vote', async() => {
        const {web3, address} = web3switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            plasmaPK: Sign.generatePrivateKey().toString('hex'),
        });
        const txHash = await twoKeyProtocol.DecentralizedNation.countPlasmaVotes(votingCampaign, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        // referralLink = await twoKeyProtocol.DecentralizedNation.join(votingCampaign, from, { cut: 100, referralLink });
        console.log('CALCULATED', txHash);
    }).timeout(300000);

    it('should print voting results', async() => {

        const results = await twoKeyProtocol.DecentralizedNation.getVotingResults(votingCampaign);
        // referralLink = await twoKeyProtocol.DecentralizedNation.join(votingCampaign, from, { cut: 100, referralLink });
        console.log('CALCULATED', results);
    }).timeout(30000);

    it('should get campaign data', async() => {
        const res = await twoKeyProtocol.DecentralizedNation.getCampaignByVotingContractAddress(daoAddress,votingCampaign);
        console.log(res);
    })
    /*
            '0xb3fa520368f2df7bed4df5185101f303f6c7decc',
            '0xffcf8fdee72ac11b5c542428b35eef5769c409f0',
            '0x22d491bde2303f2f43325b2108d26f1eaba1e32b'
     */






});
