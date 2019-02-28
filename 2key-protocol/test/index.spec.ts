import {expect} from 'chai';
import 'mocha';
import {TwoKeyProtocol} from '../src';
import singletons from '../src/contracts/singletons';
import createWeb3, { generatePlasmaFromMnemonic } from './_web3';
import registerUserFromBackend, { IRegistryData } from './_registerUserFromBackend';
import {promisify} from '../src/utils/promisify';

const {env} = process;

// const artifacts = require('../src/contracts_deployed-develop.json');
const rpcUrl = env.RPC_URL;
const eventsNetUrl = env.PLASMA_RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const destinationAddress = env.AYDNEP_ADDRESS;
const delay = env.TEST_DELAY;
// const destinationAddress = env.DESTINATION_ADDRESS  || '0xd9ce6800b997a0f26faffc0d74405c841dfc64b7'
console.log(mainNetId);
const addressRegex = /^0x[a-fA-F0-9]{40}$/;
const maxConverterBonusPercent = 23;
const pricePerUnitInETHOrUSD = 5;
const maxReferralRewardPercent = 15;
const moderatorFeePercentage = 1;
const minContributionETHorUSD = 5;
const maxContributionETHorUSD = 1000;
const now = new Date();
const campaignStartTime = Math.round(new Date(now.valueOf()).setDate(now.getDate() - 30) / 1000);
const campaignEndTime = Math.round(new Date(now.valueOf()).setDate(now.getDate() + 30) / 1000);
const twoKeyEconomy = singletons.TwoKeyEconomy.networks[mainNetId].address;
const twoKeyAdmin = singletons.TwoKeyAdmin.networks[mainNetId].address;

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
console.log(syncTwoKeyNetId);
console.log(singletons.TwoKeyEventSource.networks[mainNetId].address);
console.log(singletons.TwoKeyEconomy.networks[mainNetId].address);

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
b0057716d5917badaf911b193b12b910811c1497b5bada8d7711f758981c3773 0x1df62f291b2e969fb0849d99d9ce41e2f137006e
77c5495fbb039eed474fc940f29955ed0531693cc9212911efd35dff0373153f 0x610bb1573d1046fcb8a70bbbd395754cd57c2b60
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
    guest: () => createWeb3('mnemonic words should be here but for some reason they are missing', rpcUrl),
};

const links = {
    deployer: '',
    aydnep: '',
    gmail: '',
    test4: '',
    renata: '',
    uport: '',
    gmail2: '',
    aydnep2: '',
    test: '',
};

const users = {
        'deployer': {
            name: 'DEPLOYER',
            email: 'support@2key.network',
            fullname:  'deployer account',
            walletname: 'DEPLOYER-wallet',
        },
        'aydnep': {
            name: 'Aydnep',
            email: 'aydnep@gmail.com',
            fullname:  'aydnep account',
            walletname: 'Aydnep-wallet',
        },
        'nikola': {
            name: 'Nikola',
            email: 'nikola@2key.co',
            fullname: 'Nikola Madjarevic',
            walletname: 'Nikola-wallet',
        },
        'andrii': {
            name: 'Andrii',
            email: 'andrii@2key.co',
            fullname: 'Andrii Pindiura',
            walletname: 'Andrii-wallet',

        },
        'Kiki': {
            name: 'Kiki',
            email: 'kiki@2key.co',
            fullname: 'Erez Ben Kiki',
            walletname: 'Kiki-wallet',
        },
        'gmail': {
            name: 'gmail',
            email: 'aydnep@gmail.com',
            fullname: 'gmail account',
            walletname: 'gmail-wallet',
        },
        'test4': {
            name: 'test4',
            email: 'test4@mailinator.com',
            fullname: 'test4 account',
            walletname: 'test4-wallet',
        },
        'renata': {
            name: 'renata',
            email: 'renata.pindiura@gmail.com',
            fullname: 'renata account',
            walletname: 'renata-wallet',
        },
        'uport': {
            name: 'uport',
            email: 'aydnep_uport@gmail.com',
            fullname: 'uport account',
            walletname: 'uport-wallet',
        },
        'gmail2': {
            name: 'gmail2',
            email: 'aydnep+2@gmail.com',
            fullname: 'gmail2 account',
            walletname: 'gmail2-wallet',
        },
        'aydnep2': {
            name: 'aydnep2',
            email: 'aydnep+2@aydnep.com.ua',
            fullname: 'aydnep2 account',
            walletname: 'aydnep2-wallet',
        },
        'test': {
            name: 'test',
            email: 'test@gmail.com',
            fullname: 'test account',
            walletname: 'test-wallet',
        },
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
const acquisitionCurrency = 'ETH';
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
const tryToRegisterUser = async (username, from) => {
    console.log('REGISTERING', username);
    const user = users[username.toLowerCase()];
    const registerData: IRegistryData = {};
    try  {
        registerData.signedUser = await twoKeyProtocol.Registry.signUserData2Registry(from, user.name, user.fullname, user.email)
    } catch {
        console.log('Error in Registry.signUserData');
    }
    try {
        registerData.signedWallet = await twoKeyProtocol.Registry.signWalletData2Registry(from, user.name, user.walletname);
    } catch {
        console.log('Error in Registry.singWalletData');
    }
    try {
        registerData.signedPlasma = await twoKeyProtocol.Registry.signPlasma2Ethereum(from);
    } catch {
        console.log('Error Registry.signPlasma');
    }
    try {
        registerData.signedEthereum = await twoKeyProtocol.PlasmaEvents.signPlasmaToEthereum(from);
    } catch {
        console.log('Error Plasma.signEthereum');
    }
    let registerReceipts;
    try {
        registerReceipts = await registerUserFromBackend(registerData);
    } catch (e) {
        console.log(e);
    }

    return registerReceipts;
    // console.log('REGISTER RESULT', register);
};
describe('TwoKeyProtocol', () => {
    let from: string;
    before(function () {
        this.timeout(60000);
        return new Promise(async (resolve, reject) => {
            try {
                const {web3, address} = web3switcher.deployer();
                from = address;
                twoKeyProtocol = new TwoKeyProtocol({
                    web3,
                    networks: {
                        mainNetId,
                        syncTwoKeyNetId,
                    },
                    eventsNetUrl,
                    plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_DEPLOYER).privateKey,
                });

                // console.log('JS IPFS', await twoKeyProtocol.Utils.ipfsAdd(`alert('Hello FROM IPFS'); console.log('Hello from IPFS'); window.helloIPFS = 'hello from ipfs';`));
                await tryToRegisterUser('Deployer', from);
                // const signature = await twoKeyProtocol.Registry.signUserData2Registry(from, 'DEPLOYER','DEPLOYER','aydnep@2key.network');
                // console.log('SIGNATURE FOR REGISTRY', signature);
                const {balance} = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(env.AYDNEP_ADDRESS), {inWei: true});
                const {balance: adminBalance} = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(singletons.TwoKeyAdmin.networks[mainNetId].address), {inWei: true});
                console.log(adminBalance);
                let numberOfProposals = await twoKeyProtocol.Congress.getNumberOfProposals();
                console.log('Number of proposals is: ' + numberOfProposals);
                if (numberOfProposals == 0) {
                    console.log('Contractor does not have enough 2key tokens. Submitting a proposal to transfer');
                    const admin = twoKeyProtocol.twoKeyAdmin;
                    let transactionBytecode =
                        "0x9ffe94d9e31c0ffa000000000000000000000000b3fa520368f2df7bed4df5185101f303f6c7decc000000000000000000000000000000000000000000000000002386f26fc10000";
                    let txHash = twoKeyProtocol.Congress.newProposal(
                        twoKeyProtocol.twoKeyAdmin.address,
                        "Send some tokens to contractor",
                        transactionBytecode,
                        from);

                    resolve(txHash);
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

    it('should return acquisition submodule', async () => {
        const submoduleJS = await twoKeyProtocol.Utils.getSubmodule('cba508abbecc7f07ea7f5303279b631c418db248257c51800b5beeb0c13663cb', 'acquisition');
        expect(submoduleJS.length).to.be.gt(0);
    }).timeout(60000);

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
    }).timeout(60000);

    it('should save balance to ipfs', () => {
        return twoKeyProtocol.Utils.ipfsAdd(aydnepBalance).then((hash) => {
            console.log('IPFS hash', hash);
            expect(hash).to.be.a('string');
        });
    }).timeout(60000);

    it('should read from ipfs', () => {
        return twoKeyProtocol.Utils.getOffchainDataFromIPFSHash('QmTiZzUGHaQz6np6WpFwMv5zKqLLgW3uM6a4ow2tht642j').then((data) => {
            console.log('IPFS data', data);
            // expect(hash).to.be.a('string');
        });
    }).timeout(60000);

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
    }).timeout(60000);

    it(`should transfer ether to ${ethDstAddress}`, async () => {
        if (parseInt(mainNetId, 10) > 4) {
            // const gasLimit = await twoKeyProtocol.getETHTransferGas(twoKeyProtocolAydnep.getAddress(), 1);
            txHash = await twoKeyProtocol.transferEther(ethDstAddress, twoKeyProtocol.Utils.toWei(10, 'ether'), from, 6000000000);
            console.log('Transfer Ether', txHash, typeof txHash);
            const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
            const status = receipt && receipt.status;
            expect(status).to.be.equal('0x1');
        } else {
            expect(true);
        }
    }).timeout(60000);

    it('should return a balance for address', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });
        await tryToRegisterUser('Aydnep', from);
        const balance = twoKeyProtocol.Utils.balanceFromWeiString(await twoKeyProtocol.getBalance(from), {inWei: true});
        console.log('SWITCH USER', balance.balance);
        return expect(balance).to.exist
            .to.haveOwnProperty('gasPrice')
        // .to.be.equal(twoKeyProtocol.getGasPrice());
    }).timeout(60000);

    it('should set eth-dolar rate', async() => {
        txHash = await twoKeyProtocol.TwoKeyExchangeContract.setValue('USD', true, 91287027178099998720, from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        let value = await twoKeyProtocol.TwoKeyExchangeContract.getRatesETHFiat('USD', from);
        console.log(value);
    }).timeout(60000);

    it('should show token symbol of economy', async () => {
        const tokenSymbol = await twoKeyProtocol.ERC20.getERC20Symbol(twoKeyEconomy);
        console.log(tokenSymbol);
        expect(tokenSymbol).to.be.equal('2KEY');
    }).timeout(10000);


    let campaignData;

    it('should check a user info', async () => {
        const isAddressRegistered = await twoKeyProtocol.Registry.checkIfAddressIsRegistered(from);
        console.log(`Address ${from} ${isAddressRegistered ? 'REGISTERED' : 'NOT REGISTERED'} in TwoKeyReg`);
        expect(isAddressRegistered).to.true;
    }).timeout(60000);


    it('should create a new campaign Acquisition Contract', async () => {
        campaignData = {
            campaignStartTime,
            campaignEndTime,
            expiryConversion: 1000 * 60 * 60 * 24,
            maxConverterBonusPercentWei: maxConverterBonusPercent,
            pricePerUnitInETHWei: twoKeyProtocol.Utils.toWei(pricePerUnitInETHOrUSD, 'ether'),
            maxReferralRewardPercentWei: maxReferralRewardPercent,
            assetContractERC20: twoKeyEconomy,
            minContributionETHWei: twoKeyProtocol.Utils.toWei(minContributionETHorUSD, 'ether'),
            maxContributionETHWei: twoKeyProtocol.Utils.toWei(maxContributionETHorUSD, 'ether'),
            currency: acquisitionCurrency,
            tokenDistributionDate: 1,
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
        links.deployer = campaign.campaignPublicLinkKey;
        return expect(addressRegex.test(campaignAddress)).to.be.true;
    }).timeout(1200000);


    it('should proff that campaign is validated and registered properly', async() => {
        let isValidated = await twoKeyProtocol.CampaignValidator.isCampaignValidated(campaignAddress);
        expect(isValidated).to.be.equal(true);
        console.log('Campaign is validated');
    }).timeout(60000);

    it('should proof that non singleton hash is set for the campaign', async() => {
        let nonSingletonHash = await twoKeyProtocol.CampaignValidator.getCampaignNonSingletonsHash(campaignAddress);
        expect(nonSingletonHash).to.be.equal(twoKeyProtocol.AcquisitionCampaign.getNonSingletonsHash());
    }).timeout(60000);

    it('should save campaign to IPFS', async () => {
        const hash = await twoKeyProtocol.Utils.ipfsAdd(campaignData);
        console.log('HASH', hash);
        txHash = await twoKeyProtocol.AcquisitionCampaign.updateOrSetIpfsHashPublicMeta(campaignAddress, hash, from);
        console.log(txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log(`TX ${txHash} mined`);
        const campaignMeta = await twoKeyProtocol.AcquisitionCampaign.getPublicMeta(campaignAddress,from);
        console.log('IPFS:', hash, campaignMeta);
        expect(campaignMeta.meta.assetContractERC20).to.be.equal(campaignData.assetContractERC20);
    }).timeout(60000);
    // it('should print balance after campaign created', printBalances).timeout(15000);

    it('should transfer assets to campaign', async () => {
        txHash = await twoKeyProtocol.transfer2KEYTokens(campaignAddress, twoKeyProtocol.Utils.toWei(1234, 'ether'), from);
        console.log(twoKeyProtocol.Utils.toWei(1234, 'ether'));
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const balance = twoKeyProtocol.Utils.fromWei(await twoKeyProtocol.AcquisitionCampaign.checkInventoryBalance(campaignAddress, from)).toString();
        console.log('Campaign Balance', balance);
        expect(parseFloat(balance)).to.be.equal(1234);
    }).timeout(600000);

    it('should get user public link', async () => {
        try {
            const publicLink = await twoKeyProtocol.AcquisitionCampaign.getPublicLinkKey(campaignAddress, from);
            console.log('User Public Link', publicLink);
            expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
        } catch (e) {
            throw e;
        }
    }).timeout(10000);



    it('should check for the moderator and contractor in registry after campaign is created and registered', async() => {
        console.log(from);
        const addressesWhereUserIsContractor = await twoKeyProtocol.Registry.getCampaignsWhereUserIsContractor(from);
        const addressesWhereUserIsModerator = await twoKeyProtocol.Registry.getCampaignsWhereUserIsModerator(from);

        console.log("Contractor: " + addressesWhereUserIsContractor);
        console.log("Moderator: " + addressesWhereUserIsModerator);
    }).timeout(60000);

    it('should visit campaign as guest', async () => {
        const {web3, address} = web3switcher.guest();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic('mnemonic words should be here but for some reason they are missing').privateKey,
        });
        txHash = await twoKeyProtocol.AcquisitionCampaign.visit(campaignAddress, links.deployer);
        console.log(txHash);
        expect(txHash.length).to.be.gt(0);
    }).timeout(60000);

    it('should create a join link', async () => {
        const {web3, address} = web3switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_GMAIL).privateKey,
        });
        console.log('Gmail plasma', await promisify(twoKeyProtocol.plasmaWeb3.eth.getAccounts, []));
        await tryToRegisterUser('Gmail', from);
        txHash = await twoKeyProtocol.AcquisitionCampaign.visit(campaignAddress, links.deployer);
        console.log('isUserJoined', await twoKeyProtocol.AcquisitionCampaign.isAddressJoined(campaignAddress, from));
        const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, from, {
            cut: 50,
            referralLink: links.deployer
        });
        console.log('2) gmail offchain REFLINK', hash);
        links.gmail = hash;
        expect(hash).to.be.a('string');
    }).timeout(60000);

    it('should show maximum referral reward after ONE referrer', async() => {
        const {web3, address} = web3switcher.test4();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST4).privateKey,
        });
        await tryToRegisterUser('Test4', from);
        txHash = await twoKeyProtocol.AcquisitionCampaign.visit(campaignAddress, links.gmail);
        // console.log('isUserJoined', await twoKeyProtocol.AcquisitionCampaign.isAddressJoined(campaignAddress, from));
        let maxReward = await twoKeyProtocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(campaignAddress, from, links.gmail);
        console.log(`TEST4, BEFORE JOIN Estimated maximum referral reward: ${maxReward}%`);
        expect(maxReward).to.be.gte(7.5);
    }).timeout(60000);

    it('==> should print available amount of tokens before conversion', async() => {
        const availableAmountOfTokens = await twoKeyProtocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(campaignAddress,from);
        console.log('Available amount of tokens before conversion is: ' + availableAmountOfTokens);
        expect(availableAmountOfTokens).to.be.equal(1234);
    }).timeout(60000);

    it('should buy some tokens', async () => {
        console.log('4) buy from test4 REFLINK', links.gmail);

        txHash = await twoKeyProtocol.AcquisitionCampaign.joinAndConvert(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETHorUSD, 'ether'), links.gmail, from);
        console.log(txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

        // const campaigns = await twoKeyProtocol.getCampaignsWhereConverter(from);
        // console.log(campaigns);
        expect(txHash).to.be.a('string');
    }).timeout(60000);

    it('==> should print available amount of tokens before conversion', async() => {
        const availableAmountOfTokens = await twoKeyProtocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(campaignAddress,from);
        const { totalTokens } = await twoKeyProtocol.AcquisitionCampaign.getEstimatedTokenAmount(campaignAddress, false, twoKeyProtocol.Utils.toWei(minContributionETHorUSD, 'ether'));
        console.log('Available amount of tokens before conversion is: ' + availableAmountOfTokens, totalTokens);
        expect(availableAmountOfTokens).to.be.lte(1234 - totalTokens);
    }).timeout(60000);

    it('should join as test4', async () => {
        // twoKeyProtocol.unsubscribe2KeyEvents();
        // const hash = await twoKeyProtocol.AcquisitionCampaign.joinAndSetPublicLinkWithCut(campaignAddress, from, refLink, {cut: 33});
        const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, from, {
            cut: 33,
            referralLink: links.gmail
        });
        links.test4 = hash;
        console.log('isUserJoined', await twoKeyProtocol.AcquisitionCampaign.isAddressJoined(campaignAddress, from));
        console.log('3) test4 Cutted REFLINK', links.gmail);
        expect(hash).to.be.a('string');
    }).timeout(600000);

    it('should print amount of tokens that user want to buy', async () => {
        const tokens = await twoKeyProtocol.AcquisitionCampaign.getEstimatedTokenAmount(campaignAddress, false, twoKeyProtocol.Utils.toWei(minContributionETHorUSD, 'ether'));
        console.log(tokens);
        expect(tokens.totalTokens).to.gte(0);
    });

    it('should print joined_from', async () => {
        const { contractor } = await twoKeyProtocol.Utils.getOffchainDataFromIPFSHash(links.gmail);
        console.log('joined_from test4', await twoKeyProtocol.PlasmaEvents.getJoinedFrom(campaignAddress, contractor, twoKeyProtocol.plasmaAddress));
    }).timeout(60000);


    it('should show maximum referral reward after TWO referrer', async() => {
        const {web3, address} = web3switcher.renata();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_RENATA).privateKey,
        });
        await tryToRegisterUser('Renata', from);
        console.log('isUserJoined', await twoKeyProtocol.AcquisitionCampaign.isAddressJoined(campaignAddress, from));
        txHash = await twoKeyProtocol.AcquisitionCampaign.visit(campaignAddress, links.test4);
        console.log('VISIT', txHash);
        const maxReward = await twoKeyProtocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(campaignAddress, from, links.test4);
        console.log(`RENATA, Estimated maximum referral reward: ${maxReward}%`);

        expect(maxReward).to.be.gte(5.025);
    }).timeout(60000);

    it('should joinOffchain as Renata', async () => {
        const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, from, {
            cut: 20,
            referralLink: links.test4
        });
        links.renata = hash;
        // const hash = await twoKeyProtocol.AcquisitionCampaign.joinAndSetPublicLinkWithCut(campaignAddress, refLink, 1);
        console.log('5) Renata offchain REFLINK', links.renata);
        expect(hash).to.be.a('string');
    }).timeout(600000);

    it('==> should print available amount of tokens before conversion', async() => {
        const availableAmountOfTokens = await twoKeyProtocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(campaignAddress,from);
        console.log('Available amount of tokens before conversion is: ' + availableAmountOfTokens);
    }).timeout(60000);

    it('should register gmail', async() => {
        const {web3, address} = web3switcher.gmail2();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_GMAIL2).privateKey,
        });
        await tryToRegisterUser('Gmail2', from);
    }).timeout(60000);

    it('should buy some tokens from uport', async () => {
        const {web3, address} = web3switcher.uport();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_UPORT).privateKey,
        });
        await tryToRegisterUser('Uport', from);
        await twoKeyProtocol.AcquisitionCampaign.visit(campaignAddress, links.renata);

        console.log('6) uport buy from REFLINK', links.renata);
        const txHash = await twoKeyProtocol.AcquisitionCampaign.joinAndConvert(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETHorUSD * 1.5, 'ether'), links.renata, from);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log(txHash);
        expect(txHash).to.be.a('string');
    }).timeout(60000);

    it('==> should print available amount of tokens after conversion', async() => {
        const availableAmountOfTokens = await twoKeyProtocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(campaignAddress,from);
        console.log('Available amount of tokens after conversion is: ' + availableAmountOfTokens);
    }).timeout(60000);

    it('should transfer arcs to gmail2', async () => {
        console.log('7) transfer to gmail2 REFLINK', links.renata);
        txHash = await twoKeyProtocol.AcquisitionCampaign.joinAndShareARC(campaignAddress, from, links.renata, env.GMAIL2_ADDRESS);
        console.log(txHash);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should buy some tokens from gmail2', async () => {
        const {web3, address} = web3switcher.gmail2();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_GMAIL2).privateKey,
        });
        await tryToRegisterUser('Gmail2', from);

        const arcs = await twoKeyProtocol.AcquisitionCampaign.getBalanceOfArcs(campaignAddress, from);
        console.log('GMAIL2 ARCS', arcs);
        txHash = await twoKeyProtocol.AcquisitionCampaign.convert(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETHorUSD * 1.1, 'ether'), from);
        // txHash = await twoKeyProtocol.transferEther(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETHorUSD * 1.1, 'ether'), from);
        console.log('HASH', txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);

    it('should register test', async() => {
        const {web3, address} = web3switcher.test();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST).privateKey,
        });
        await tryToRegisterUser('Test', from);
    }).timeout(60000);

    it('should transfer arcs from new user to test', async () => {
        const {web3, address} = web3switcher.aydnep2();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP2).privateKey,
        });
        await tryToRegisterUser('Aydnep2', from);

        const refReward = await twoKeyProtocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(campaignAddress, from, links.renata);
        console.log(`Max estimated referral reward: ${refReward}%`);
        txHash = await twoKeyProtocol.AcquisitionCampaign.joinAndShareARC(campaignAddress, from, links.renata, env.TEST_ADDRESS);
        console.log(txHash);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        const status = receipt && receipt.status;
        expect(status).to.be.equal('0x1');
    }).timeout(60000);

    it('should buy some tokens from test', async () => {
        const {web3, address} = web3switcher.test();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST).privateKey,
        });
        await tryToRegisterUser('Test', from);

        // txHash = await twoKeyProtocol.transferEther(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETHorUSD * 1.1, 'ether'), from);
        txHash = await twoKeyProtocol.AcquisitionCampaign.convert(campaignAddress, twoKeyProtocol.Utils.toWei(minContributionETHorUSD * 1.1, 'ether'), from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);

    it('should return all pending converters', async () => {
        console.log("Test where we'll fetch all pending converters");
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log(addresses);
    }).timeout(60000);

    it('should return all pending converters from contractor', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });

        const addresses = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log("Addresses: " + addresses);
    }).timeout(60000);

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
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });
        let txHash = await twoKeyProtocol.AcquisitionCampaign.approveConverter(campaignAddress, env.TEST4_ADDRESS, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        txHash = await twoKeyProtocol.AcquisitionCampaign.approveConverter(campaignAddress,env.GMAIL2_ADDRESS, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        /*
        txHash = await twoKeyProtocol.AcquisitionCampaign.approveConverter(campaignAddress,env.RENATA_ADDRESS, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        */
        const allApproved = await twoKeyProtocol.AcquisitionCampaign.getApprovedConverters(campaignAddress, from);
        console.log('Approved addresses: ', allApproved);

        expect(allApproved[0]).to.be.equal(env.TEST4_ADDRESS);
        const allPendingAfterApproved = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log('All pending after approval: ' + allPendingAfterApproved);
        expect(allPendingAfterApproved.length).to.be.equal(2);
    }).timeout(60000);

    it('should get converter conversion ids', async() => {
        console.log('Test where we have to print conversion ids for the converter');
        let conversionIds = await twoKeyProtocol.AcquisitionCampaign.getConverterConversionIds(campaignAddress, env.TEST4_ADDRESS, from);
        console.log('For the converter: ' + env.TEST4_ADDRESS + 'conversion ids are:' + conversionIds);
    }).timeout(60000);

    it('should reject converter', async () => {
        console.log("Test where contractor / moderator can reject converter to execute lockup");
        txHash = await twoKeyProtocol.AcquisitionCampaign.rejectConverter(campaignAddress, env.TEST_ADDRESS, from);
        console.log(txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

        const allRejected = await twoKeyProtocol.AcquisitionCampaign.getAllRejectedConverters(campaignAddress, from);
        console.log("Rejected addresses: ", allRejected);

        const allPendingAfterRejected = await twoKeyProtocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, from);
        console.log('All pending after rejection: ', allPendingAfterRejected);
        expect(allRejected[0]).to.be.equal(env.TEST_ADDRESS);
        expect(allPendingAfterRejected.length).to.be.equal(1);
    }).timeout(60000);

    /*
    it('should be executed conversion by contractor' ,async() => {
        let conversionIdsForRenata = await twoKeyProtocol.AcquisitionCampaign.getConverterConversionIds(campaignAddress, env.RENATA_ADDRESS, from);
        console.log('Conversion ids for Renata' + conversionIdsForRenata);
        const txHash = await twoKeyProtocol.AcquisitionCampaign.executeConversion(campaignAddress, conversionIdsForRenata[0], from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);
    */

    it('should be executed conversion by contractor' ,async() => {
        let conversionIdsForGmail2 = await twoKeyProtocol.AcquisitionCampaign.getConverterConversionIds(campaignAddress, env.GMAIL2_ADDRESS, from);
        console.log('Conversion ids for Gmail2:', conversionIdsForGmail2);
        const txHash = await twoKeyProtocol.AcquisitionCampaign.executeConversion(campaignAddress, conversionIdsForGmail2[0], from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);

    it('should print campaigns where user converter', async() => {
        const {web3, address} = web3switcher.test4();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST4).privateKey,
        });
        // const campaigns = await twoKeyProtocol.Lockup.getCampaignsWhereConverter(from);
        // console.log(campaigns);
    });

    it('should execute conversion and create lockup contract', async () => {
        const {web3, address} = web3switcher.test4();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST4).privateKey,
        });
        const txHash = await twoKeyProtocol.AcquisitionCampaign.executeConversion(campaignAddress, 0, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);

    it('should show campaign summary', async() => {
        const summary = await twoKeyProtocol.AcquisitionCampaign.getCampaignSummary(campaignAddress, from);
        console.log(summary);
    }).timeout(60000);

    it('should return addresses of lockup contracts for converter', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        console.log('Lockup contracts addresses : ' + addresses);
        expect(addresses.length).to.be.equal(1);
    }).timeout(60000);

    it('should pull down base tokens amount from lockup from maintainer address', async() => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        let txHash = await twoKeyProtocol.AcquisitionCampaign.withdrawTokens(addresses[0],0,from);
    }).timeout(60000);

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
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });

        const isContractor:boolean = await twoKeyProtocol.AcquisitionCampaign.isAddressContractor(campaignAddress,from);
        console.log('Aydnep is contractor: ' + isContractor);
        const balanceOfContract = await twoKeyProtocol.getBalance(campaignAddress);
        console.log('contract balance', twoKeyProtocol.Utils.balanceFromWeiString(balanceOfContract, {
            inWei: true,
            toNum: true
        }).balance);

        const contractorBalance = await twoKeyProtocol.AcquisitionCampaign.getContractorBalance(campaignAddress,from);
        console.log('Contractor balance: ' + contractorBalance);
        const moderatorBalance = await twoKeyProtocol.AcquisitionCampaign.getModeratorBalance(campaignAddress,from);
        console.log('Moderator balance: ' + moderatorBalance);
        const hash = await twoKeyProtocol.AcquisitionCampaign.contractorWithdraw(campaignAddress,from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(hash);
    }).timeout(60000);

    it('==> should show referrer stats per request with signature', async() => {

    }).timeout(60000);

    it('==> should get address statistics', async() => {
        let hexedValues = await twoKeyProtocol.AcquisitionCampaign.getAddressStatistic(campaignAddress, env.TEST4_ADDRESS);
        console.log(hexedValues);
        hexedValues = await twoKeyProtocol.AcquisitionCampaign.getAddressStatistic(campaignAddress, env.TEST4_ADDRESS, true);
        console.log(hexedValues);
    }).timeout(60000);

    it('==> should print moderator address', async() => {
        const moderatorAddress: string = await twoKeyProtocol.AcquisitionCampaign.getModeratorAddress(campaignAddress,from);
        console.log("Moderator address is: " + moderatorAddress);
        expect(moderatorAddress).to.be.equal('0xbae10c2bdfd4e0e67313d1ebaddaa0adc3eea5d7');
    }).timeout(60000);
    
    it('==> should moderator withdraw his balances in 2key-tokens', async() => {
        const txHash = await twoKeyProtocol.AcquisitionCampaign.moderatorAndReferrerWithdraw(campaignAddress,from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log(txHash);
    }).timeout(60000);


    it('==> should referrer withdraw his balances in 2key-tokens', async() => {
        const {web3, address} = web3switcher.renata();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });
        const txHash = await twoKeyProtocol.AcquisitionCampaign.moderatorAndReferrerWithdraw(campaignAddress,from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        console.log(txHash);
    }).timeout(60000);


    it('should print balances before cancelation', async() => {
        for (let i = 0; i < addresses.length; i++) {
            let addressCurrent = addresses[i].toString();
            let balance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyEconomy, addressCurrent);
            console.log("Address: " + addressCurrent + " ----- balance: " + balance);
        }
    }).timeout(60000);

    it('should print balances of ERC20 on lockupContracts', async () => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });
        const addresses = await twoKeyProtocol.AcquisitionCampaign.getLockupContractsForConverter(campaignAddress, env.TEST4_ADDRESS, from);
        console.log('Lockup contracts addresses : ' + addresses);
        for (let i = 0; i < addresses.length; i++) {
            let addressCurrent = addresses[i].toString();
            let balance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyEconomy, addressCurrent);
            console.log("Address: " + addressCurrent + " ----- balance: " + balance);
        }
    }).timeout(60000);

    it('should get all whitelisted addresses', async() => {
        const addresses = await twoKeyProtocol.Congress.getAllMembersForCongress(from);
        // console.log(addresses);
        expect(addresses.length).to.be.equal(3);
    }).timeout(60000);

    it('should get rate from upgradable exchange', async() => {
        const rate = await twoKeyProtocol.UpgradableExchange.getRate(from);

        console.log('Rate is : ' + rate);
        expect(rate.toString()).to.be.equal("0.095");
    }).timeout(60000);

    it('should print currency', async() => {
        const currency = await twoKeyProtocol.AcquisitionCampaign.getAcquisitionCampaignCurrency(campaignAddress, from);
        expect(currency).to.be.equal(acquisitionCurrency);
        console.log('Currency is: '+ currency);
    }).timeout(60000);

    it('should get moderator total earnings in campaign', async() => {
        const totalEarnings = await twoKeyProtocol.AcquisitionCampaign.getModeratorTotalEarnings(campaignAddress,from);
        console.log('Moderator total earnings: '+ totalEarnings);
    }).timeout(60000);

    it('should get statistics for the address from the contract', async() => {
        let stats = await twoKeyProtocol.AcquisitionCampaign.getAddressStatistic(campaignAddress,env.RENATA_ADDRESS);
        console.log(stats);
    }).timeout(60000);

    it('should print balance of left ERC20 on the Acquisition contract', async() => {
        let balance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyEconomy, campaignAddress);
        console.log(balance);
    }).timeout(60000);

    it('should check the amount of tokens for the offline conversion', async() => {
        console.log('Trying to resolve base and bonus amount of tokens for this kind of conversion');
        let obj = await twoKeyProtocol.AcquisitionCampaign.getEstimatedTokenAmount(campaignAddress,true,twoKeyProtocol.Utils.toWei(50, 'ether'));
        console.log(obj);
    }).timeout(60000);

    it('should create an offline(fiat) conversion', async() => {
        const {web3, address} = web3switcher.gmail2();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });
        console.log('Trying to perform offline conversion from gmail2');
        let txHash = await twoKeyProtocol.AcquisitionCampaign.convertOffline(campaignAddress, from, 50);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);

    it('should check conversion ids conversion handler after conversion is created', async() => {
        let conversionIds = await twoKeyProtocol.AcquisitionCampaign.getConverterConversionIds(campaignAddress, env.GMAIL2_ADDRESS, from);
        console.log('Conversion ids for the Gmail 2 are: ' + conversionIds);
    }).timeout(60000);

    it('should check conversion object for the created fiat conversion', async() => {
        let conversion = await twoKeyProtocol.AcquisitionCampaign.getConversion(campaignAddress,4,from);
        console.log(conversion);
    }).timeout(60000);

    it('should execute conversion from contractor', async() => {
        const {web3, address} = web3switcher.aydnep();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_AYDNEP).privateKey,
        });
        console.log('Trying to execute fiat conversion from Contractor');
        let txHash = await twoKeyProtocol.AcquisitionCampaign.executeConversion(campaignAddress,4,from);
        let lockupContractAddress = await twoKeyProtocol.AcquisitionCampaign.getLockupContractAddress(campaignAddress,4,from);
        expect(lockupContractAddress).not.to.be.equal(0);
        const receipt = await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);

    it('should return number of executed conversions', async() => {
        let number = await twoKeyProtocol.AcquisitionCampaign.getNumberOfExecutedConversions(campaignAddress);
        console.log('Number of executed conversions: ' + number);
    }).timeout(60000);

    it('should return number of forwarders for the campaign', async() => {
        let numberOfForwarders = await twoKeyProtocol.PlasmaEvents.getForwardersPerCampaign(campaignAddress);
        console.log('Number of forwarders stored on plasma: ' + numberOfForwarders);
    }).timeout(60000);

    it('should check reputation points for a couple of addresses', async() => {
        console.log('Checking stats for Renata');
        let renataStats = await twoKeyProtocol.BaseReputation.getReputationPointsForAllRolesPerAddress(env.RENATA_ADDRESS);
        console.log(renataStats);

        console.log('Checking stats for Test4');
        let test4Stats = await twoKeyProtocol.BaseReputation.getReputationPointsForAllRolesPerAddress(env.TEST4_ADDRESS);
        console.log(test4Stats);

        console.log('Checking stats for contractor');
        let contractorStats = await twoKeyProtocol.BaseReputation.getReputationPointsForAllRolesPerAddress(env.AYDNEP_ADDRESS);
        console.log(contractorStats);

        console.log('Checking stats for test address');
        let rejectedConverterStats = await twoKeyProtocol.BaseReputation.getReputationPointsForAllRolesPerAddress(env.TEST_ADDRESS);
        console.log(rejectedConverterStats);


    }).timeout(60000);
});
