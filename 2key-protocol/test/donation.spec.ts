import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {TwoKeyProtocol} from "../src";
import {expect} from "chai";
import {ICreateCampaign, InvoiceERC20} from "../src/donation/interfaces";
import {promisify} from "../src/utils/promisify";
import {IPrivateMetaInformation} from "../src/acquisition/interfaces";
const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const eventsNetUrl = env.PLASMA_RPC_URL;
let i = 1;
let twoKeyProtocol: TwoKeyProtocol;
let from: string;

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
let campaignStartTime = 12345;
let campaignEndTime = 1234567;
let minDonationAmount = 0.001;
let maxDonationAmount = 1000;
let campaignGoal = 1000000000;
let conversionQuota = 5;
let isKYCRequired = true;
let shouldConvertToRefer = false;
let acceptsFiat = false;
let incentiveModel = "VANILLA_AVERAGE";
let conversionAmountEth = 1;


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
    campaignName,
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
    incentiveModel
};

const progressCallback = (name: string, mined: boolean, transactionResult: string): void => {
    console.log(`Contract ${name} ${mined ? `deployed with address ${transactionResult}` : `placed to EVM. Hash ${transactionResult}`}`);
};

describe('TwoKeyDonationCampaign', () => {

   it('should create a donation campaign', async() => {
       console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
       i++;
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


        campaignAddress = result.campaignAddress;
        links.deployer = result.campaignPublicLinkKey;
        invoiceTokenAddress = result.invoiceToken;
   }).timeout(60000);


    it('should proff that campaign is validated and registered properly', async() => {
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
        let isValidated = await twoKeyProtocol.CampaignValidator.isCampaignValidated(campaignAddress);
        expect(isValidated).to.be.equal(true);
        console.log('Campaign is validated');
    }).timeout(60000);

    it('should proof that non singleton hash is set for the campaign', async() => {
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
        let nonSingletonHash = await twoKeyProtocol.CampaignValidator.getCampaignNonSingletonsHash(campaignAddress);
        expect(nonSingletonHash).to.be.equal(twoKeyProtocol.DonationCampaign.getNonSingletonsHash());
    }).timeout(60000);

    it('should save campaign to IPFS', async () => {
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
        const campaignMeta = await twoKeyProtocol.DonationCampaign.getPublicMeta(campaignAddress,from);
        expect(campaignMeta.meta.campaignName).to.be.equal(campaignData.campaignName);
    }).timeout(120000);

    it('should get user public link', async () => {
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
        try {
            const publicLink = await twoKeyProtocol.DonationCampaign.getPublicLinkKey(campaignAddress, from);
            console.log('User Public Link', publicLink);
            expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
        } catch (e) {
            throw e;
        }
    }).timeout(10000);

    it('should get and decrypt ipfs hash', async() => {
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
        let data: IPrivateMetaInformation = await twoKeyProtocol.DonationCampaign.getPrivateMetaHash(campaignAddress, from);
        expect(data.campaignPublicLinkKey).to.be.equal(links.deployer);
    }).timeout(120000);

    it('should visit campaign as guest', async () => {
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
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
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
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
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
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
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;
        console.log('4) buy from test4 REFLINK', links.gmail);

        let txHash = await twoKeyProtocol.DonationCampaign.joinAndConvert(campaignAddress, twoKeyProtocol.Utils.toWei(conversionAmountEth, 'ether'), links.gmail, from);
        console.log(txHash);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

        expect(txHash).to.be.a('string');
    }).timeout(60000);

    it('should approve converter and execute conversion if KYC == TRUE', async() => {
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;

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
            let txHash = await twoKeyProtocol.DonationCampaign.approveConverter(campaignAddress,env.TEST4_ADDRESS,from);
            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

            console.log('Converter is successfully approved');

            let conversionId = 0;
            txHash = await twoKeyProtocol.DonationCampaign.executeConversion(campaignAddress, conversionId, from);
            await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);

            console.log('Conversion is succesfully executed');
        }
    }).timeout(60000);

    it('should proof that the invoice has been issued for executed conversion (Invoice tokens transfered)', async() => {
        console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
        i++;

        let balance = await twoKeyProtocol.ERC20.getERC20Balance(invoiceTokenAddress, env.TEST4_ADDRESS);
        balance = parseFloat(twoKeyProtocol.Utils.fromWei(balance,'ether').toString());
        expect(balance).to.be.equal(1);
    }).timeout(60000);
});
