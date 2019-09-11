import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {TwoKeyProtocol} from "../src";
import {expect} from "chai";
import {IConversion, ICreateCampaign, InvoiceERC20} from "../src/donation/interfaces";
import {promisify} from "../src/utils/promisify";
import {IPrivateMetaInformation} from "../src/acquisition/interfaces";
import singletons from "../src/contracts/singletons";
const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const eventsNetUrl = env.PLASMA_RPC_URL;
const twoKeyEconomy = singletons.TwoKeyEconomy.networks[mainNetId].address;

let i = 1;
let twoKeyProtocol: TwoKeyProtocol;
let from: string;

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

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
    guest: () => createWeb3('mnemonic words should be here bu   t for some reason they are missing', rpcUrl),
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
/**
 * Donation campaign parameters
 */

let campaignName = 'Donation for Some Services';
let tokenName = 'NikolaToken';
let tokenSymbol = 'NTKN';
let maxReferralRewardPercent = 5;
let campaignStartTime = 0;
let campaignEndTime = 9884748832;
let minDonationAmount = 0.001;
let maxDonationAmount = 1000;
let campaignGoal = 10000000000000000000000000000000;
let conversionQuota = 5;
let isKYCRequired = true;
let shouldConvertToRefer = false;
let acceptsFiat = false;
let incentiveModel = "VANILLA_AVERAGE";
let conversionAmountEth = 1;
let currency = "USD";
let endCampaignOnceGoalReached = true;
let campaignAddress: string;
let invoiceTokenAddress: string;

//Describe structure of invoice token
let invoiceToken: InvoiceERC20 = {
    tokenName,
    tokenSymbol
};

//Moderator will be AYDNEP in this case
let moderator = env.AYDNEP_ADDRESS;

//Describe initial params and attributes for the campaign

let campaignData: ICreateCampaign = {
    moderator,
    invoiceToken,
    maxReferralRewardPercent,
    campaignStartTime,
    campaignEndTime,
    minDonationAmount,
    maxDonationAmount,
    campaignGoal,
    conversionQuota,
    isKYCRequired,
    shouldConvertToRefer,
    acceptsFiat,
    incentiveModel,
    currency,
    endCampaignOnceGoalReached
};

const progressCallback = (name: string, mined: boolean, transactionResult: string): void => {
    console.log(`Contract ${name} ${mined ? `deployed with address ${transactionResult}` : `placed to EVM. Hash ${transactionResult}`}`);
};

const printTestNumber = (): void => {
    console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
    i++;
};


describe('TwoKeyDonationCampaign', () => {

   it('should create a donation campaign', async() => {
       printTestNumber();
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

        let result = await twoKeyProtocol.DonationCampaign.create(campaignData, campaignData, {}, from, {
            progressCallback,
            gasPrice: 150000000000,
            interval: 500,
            timeout: 600000
        });

        console.log(result);


        campaignAddress = result.campaignAddress;
        links.deployer = result.campaignPublicLinkKey;
        invoiceTokenAddress = result.invoiceToken;
   }).timeout(60000);


    it('should proff that campaign is validated and registered properly', async() => {
        printTestNumber();
        let isValidated = await twoKeyProtocol.CampaignValidator.isCampaignValidated(campaignAddress);
        expect(isValidated).to.be.equal(true);
        console.log('Campaign is validated');
    }).timeout(60000);

    it('should proof that non singleton hash is set for the campaign', async() => {
        printTestNumber();
        let nonSingletonHash = await twoKeyProtocol.CampaignValidator.getCampaignNonSingletonsHash(campaignAddress);
        expect(nonSingletonHash).to.be.equal(twoKeyProtocol.DonationCampaign.getNonSingletonsHash());
    }).timeout(60000);

    it('should get incentive model', async() => {
        printTestNumber();
        const model = await twoKeyProtocol.DonationCampaign.getIncentiveModel(campaignAddress);
        expect(model).to.be.equal(incentiveModel);
    }).timeout(60000);

    it('should save campaign to IPFS', async () => {
        printTestNumber();
        const campaignMeta = await twoKeyProtocol.DonationCampaign.getPublicMeta(campaignAddress,from);
        expect(campaignMeta.meta.currency).to.be.equal(campaignData.currency);
    }).timeout(120000);

    it('should make sure all args are properly set', async() => {
        let obj = await twoKeyProtocol.DonationCampaign.getConstantInfo(campaignAddress);
        console.log(obj);
    }).timeout(60000);

    it('should get user public link', async () => {
        printTestNumber();
        try {
            const publicLink = await twoKeyProtocol.DonationCampaign.getPublicLinkKey(campaignAddress, from);
            console.log('User Public Link', publicLink);
            expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
        } catch (e) {
            throw e;
        }
    }).timeout(10000);

    it('should get and decrypt ipfs hash', async() => {
        printTestNumber();
        let data: IPrivateMetaInformation = await twoKeyProtocol.DonationCampaign.getPrivateMetaHash(campaignAddress, from);
        expect(data.campaignPublicLinkKey).to.be.equal(links.deployer);
    }).timeout(120000);

    it('should visit campaign as guest', async () => {
        printTestNumber();
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
        let txHash = await twoKeyProtocol.DonationCampaign.visit(campaignAddress, links.deployer);
        console.log(txHash);
        expect(txHash.length).to.be.gt(0);
    }).timeout(60000);

    it('should create a join link', async () => {
        printTestNumber();
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
        let txHash = await twoKeyProtocol.DonationCampaign.visit(campaignAddress, links.deployer);
        const hash = await twoKeyProtocol.DonationCampaign.join(campaignAddress, from, {
            cut: 50,
            referralLink: links.deployer
        });
        links.gmail = hash;
        expect(hash).to.be.a('string');
    }).timeout(60000);

    it('should show maximum referral reward after ONE referrer', async() => {
        printTestNumber();
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

        let txHash = await twoKeyProtocol.DonationCampaign.visit(campaignAddress, links.gmail);

        let maxReward = await twoKeyProtocol.DonationCampaign.getEstimatedMaximumReferralReward(campaignAddress, from, links.gmail);
        console.log(`TEST4, BEFORE JOIN Estimated maximum referral reward: ${maxReward}%`);
    }).timeout(60000);

    it('should donate 1 ether to campaign', async () => {
        printTestNumber();
        console.log('4) buy from test4 REFLINK', links.gmail);

        let txHash = await twoKeyProtocol.DonationCampaign.joinAndConvert(campaignAddress, twoKeyProtocol.Utils.toWei(conversionAmountEth, 'ether'), links.gmail, from);
        console.log(txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

        expect(txHash).to.be.a('string');
    }).timeout(60000);

    it('should visit campaign from same referral link', async() => {
        printTestNumber();
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

        let txHash = await twoKeyProtocol.DonationCampaign.visit(campaignAddress, links.gmail);
        let maxReward = await twoKeyProtocol.DonationCampaign.getEstimatedMaximumReferralReward(campaignAddress, from, links.gmail);
        console.log(`TEST4, BEFORE JOIN Estimated maximum referral reward: ${maxReward}%`);
    }).timeout(60000);

    it('should donate 2 ether to campaign', async() => {
        printTestNumber();
        console.log('4) buy from test4 REFLINK', links.gmail);

        let txHash = await twoKeyProtocol.DonationCampaign.joinAndConvert(campaignAddress, twoKeyProtocol.Utils.toWei(conversionAmountEth, 'ether'), links.gmail, from);
        console.log(txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

        expect(txHash).to.be.a('string');
    }).timeout(60000);

    it('should get all pending converters in case KYC is required', async() => {
        printTestNumber();
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

        if(isKYCRequired == true) {
            let pendingConverters = await twoKeyProtocol.DonationCampaign.getAllPendingConverters(campaignAddress, from);
            expect(pendingConverters.length).to.be.equal(2);
        }

    }).timeout(60000);

    it('should approve converter and execute conversion if KYC == TRUE', async() => {
        printTestNumber();

        if(isKYCRequired == true) {
            let txHash = await twoKeyProtocol.DonationCampaign.approveConverter(campaignAddress,env.TEST4_ADDRESS,from);
            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

            console.log('Converter is successfully approved');

            let conversionId = 0;
            txHash = await twoKeyProtocol.DonationCampaign.executeConversion(campaignAddress, conversionId, from);
            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

            console.log('Conversion is succesfully executed');
        } else {
            console.log('For this campaign KYC is not required since that -> This test case is not relevant!')
        }
    }).timeout(60000);

    it('should reject converter if KYC == TRUE', async() => {
        printTestNumber();
        if(isKYCRequired == true) {
            let txHash = await twoKeyProtocol.DonationCampaign.rejectConverter(campaignAddress,env.RENATA_ADDRESS,from);
            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
            console.log('Converter is successfully rejected');
        } else {
            console.log('For this campaign KYC is not required since that -> This test case is not relevant!')
        }
    }).timeout(60000);

    it('should proof that the invoice has been issued for executed conversion (Invoice tokens transfered)', async() => {
        printTestNumber();

        let balance = await twoKeyProtocol.ERC20.getERC20Balance(invoiceTokenAddress, env.TEST4_ADDRESS);
        balance = parseFloat(twoKeyProtocol.Utils.fromWei(balance,'ether').toString());
        let expectedValue = 1;
        if(currency == 'USD') {
            expectedValue = 100;
        }
        expect(balance).to.be.equal(expectedValue);
    }).timeout(60000);

    it('should get conversion object', async() => {
        printTestNumber();

        let conversionId = 0;
        let conversion: IConversion = await twoKeyProtocol.DonationCampaign.getConversion(campaignAddress, conversionId, from);
        console.log(conversion);
        expect(conversion.conversionState).to.be.equal("EXECUTED");
    }).timeout(60000);

    it('should get referrer earnings', async() => {
        printTestNumber();
        let referrerBalance = await twoKeyProtocol.DonationCampaign.getReferrerBalance(campaignAddress, env.GMAIL_ADDRESS, from);
        expect(referrerBalance).to.be.equal(50);
    }).timeout(60000);

    it('should get reserved amount for referrers', async() => {
        printTestNumber();
        let referrerReservedAmount = await twoKeyProtocol.DonationCampaign.getReservedAmount2keyForRewards(campaignAddress);
        expect(referrerReservedAmount).to.be.equal(50);
    }).timeout(60000);

    it('should check is address contractor', async() => {
        printTestNumber();

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
        let isAddressContractor = await twoKeyProtocol.DonationCampaign.isAddressContractor(campaignAddress, from);
        expect(isAddressContractor).to.be.equal(true);
    }).timeout(60000);

    it('should start hedging some ether', async() => {
        printTestNumber();
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
        let approvedMinConversionRate = 1000;
        let amountToBeHedged = 70000000000000000;
        const hash = await twoKeyProtocol.UpgradableExchange.startHedgingEth(amountToBeHedged, approvedMinConversionRate, from);
        console.log(hash);
    }).timeout(50000);

    it('should get contractor balance and total earnings', async() => {
        printTestNumber();
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
        let earnings = await twoKeyProtocol.DonationCampaign.getContractorBalanceAndTotalProceeds(campaignAddress, from);
        console.log(earnings);
    }).timeout(60000);

    it('should test if address is joined', async() => {
        printTestNumber();
        let isJoined = await twoKeyProtocol.DonationCampaign.isAddressJoined(campaignAddress,from);
        console.log(isJoined);
    }).timeout(60000);

    it('should get how much user have spent', async() => {
        printTestNumber();
        let amountSpent = await twoKeyProtocol.DonationCampaign.getAmountConverterSpent(campaignAddress, env.TEST4_ADDRESS);
        expect(amountSpent).to.be.equal(1);
    }).timeout(60000);

    it('should show how much user can donate', async() => {
        printTestNumber();
        let leftToDonate = await twoKeyProtocol.DonationCampaign.howMuchUserCanContribute(campaignAddress, env.TEST4_ADDRESS, from);
        console.log(leftToDonate);
        let expectedValue = conversionAmountEth;
        if(currency == 'USD') {
            expectedValue = conversionAmountEth * 100;
        }
        expect(leftToDonate).to.be.equal(maxDonationAmount-expectedValue);
    }).timeout(60000);

    it('should show address statistic', async() => {
        printTestNumber();
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
        let stats = await twoKeyProtocol.DonationCampaign.getAddressStatistic(campaignAddress,env.TEST4_ADDRESS, '0x0000000000000000000000000000000000000000',{from});
        console.log(stats);
    }).timeout(60000);

    it('should show stats for referrer', async() => {
        printTestNumber();
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

        let signature = await twoKeyProtocol.PlasmaEvents.signReferrerToGetRewards();
        let stats = await twoKeyProtocol.DonationCampaign.getReferrerBalanceAndTotalEarningsAndNumberOfConversions(campaignAddress, signature);
        console.log(stats);
    }).timeout(60000);

    it('should get balance of TwoKeyEconomy tokens on DonationCampaign', async() => {
        printTestNumber();
        let balance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyEconomy, campaignAddress);
        console.log('ERC20 TwoKeyEconomy balance on this contract is : ' + balance);
    }).timeout(60000);



    it('referrer should withdraw his earnings', async() => {
        printTestNumber();
        let txHash = await twoKeyProtocol.DonationCampaign.moderatorAndReferrerWithdraw(campaignAddress, false, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);

    it('should get stats for the contract from upgradable exchange', async() => {
        let stats = await twoKeyProtocol.UpgradableExchange.getStatusForTheContract(campaignAddress, from);
        console.log(stats);
    }).timeout(60000);

});
