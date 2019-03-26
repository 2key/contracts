import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {TwoKeyProtocol} from "../src";
import {expect} from "chai";
import {ICreateCampaign, InvoiceERC20} from "../src/donation/interfaces";
import {promisify} from "../src/utils/promisify";
const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const eventsNetUrl = env.PLASMA_RPC_URL;

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
let conversionQuota = 1;
let isKYCRequired = false;
let shouldConvertToRefer = false;
let incentiveModel = 2;

let campaignAddress: string;

//Describe structure of invoice token
let invoiceToken: InvoiceERC20 = {
    tokenName,
    tokenSymbol
};

//Moderator will be AYDNEP in this case
let moderator = env.AYDNEP_ADDRESS;

//Describe initial params and attributes for the campaign

let campaign: ICreateCampaign = {
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
    incentiveModel
};

const progressCallback = (name: string, mined: boolean, transactionResult: string): void => {
    console.log(`Contract ${name} ${mined ? `deployed with address ${transactionResult}` : `placed to EVM. Hash ${transactionResult}`}`);
};

describe('TwoKeyDonationCampaign', () => {

   it('should create a donation campaign', async() => {
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

        let result = await twoKeyProtocol.DonationCampaign.create(campaign, from, {
            progressCallback,
            gasPrice: 150000000000,
            interval: 500,
            timeout: 600000
        });

        campaignAddress = result.campaignAddress;
        links.deployer = result.campaignPublicLinkKey;
        console.log(links.deployer);
   }).timeout(60000);

   it('should proof that campaign is set and validated properly', async() => {
       console.log(campaignAddress);
       let isValidated = await twoKeyProtocol.CampaignValidator.isCampaignValidated(campaignAddress);
       expect(isValidated).to.be.equal(true);
       console.log('Campaign is validated');
   }).timeout(60000);

   it('should proof that non singleton hash is set for the campaign', async() => {
        let nonSingletonHash = await twoKeyProtocol.CampaignValidator.getCampaignNonSingletonsHash(campaignAddress);
        expect(nonSingletonHash).to.be.equal(twoKeyProtocol.AcquisitionCampaign.getNonSingletonsHash());
    }).timeout(60000);

   it('should upload campaign to ipfsHash and save it on the contract', async() => {
       const hash = await twoKeyProtocol.Utils.ipfsAdd(campaign);
       console.log('HASH', hash);
       let txHash = await twoKeyProtocol.DonationCampaign.updateOrSetIpfsHashPublicMeta(campaignAddress,hash, from);
       await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
   }).timeout(60000);

   it('should get public meta hash from the contract', async() => {
       let meta = await twoKeyProtocol.DonationCampaign.getPublicMeta(campaignAddress);
       console.log(meta);
   }).timeout(60000);

    it('should save contractor link as the private meta hash', async() => {
        console.log(links.deployer);
        let txHash = await twoKeyProtocol.DonationCampaign.setPrivateMetaHash(campaignAddress, links.deployer, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(60000);

    it('should get and decrypt ipfs hash', async() => {
        let data = await twoKeyProtocol.DonationCampaign.getPrivateMetaHash(campaignAddress, from);
        console.log(data);
        expect(data).to.be.equal(links.deployer);
    }).timeout(60000);

   it('should get user public link', async () => {
       try {
           const publicLink = await twoKeyProtocol.DonationCampaign.getPublicLinkKey(campaignAddress, from);
           console.log('User Public Link', publicLink);
           expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
       } catch (e) {
           throw e;
       }
   }).timeout(10000);

   it('should get incentive model from contract', async() => {
       let incentiveModel = await twoKeyProtocol.DonationCampaign.getIncentiveModel(campaignAddress);
       console.log(incentiveModel);
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
       let txHash = await twoKeyProtocol.DonationCampaign.visit(campaignAddress, links.deployer);
       console.log(txHash);
       expect(txHash.length).to.be.gt(0);
    }).timeout(60000);

   it('should join from contractor', async() => {
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
       const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, from, {
           cut: 2,
           referralLink: links.deployer
       });
       console.log('Gmail offchain REFLINK', hash);
       links.gmail = hash;
   }).timeout(60000);

   it('should join from gmail', async() => {
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
       console.log('Renata plasma', await promisify(twoKeyProtocol.plasmaWeb3.eth.getAccounts, []));
       let txHash = await twoKeyProtocol.DonationCampaign.visit(campaignAddress, links.gmail);
       const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, from, {
           cut: 2,
           referralLink: links.gmail
       });
       console.log('Renata offchain REFLINK', hash);
       links.renata = hash;
   }).timeout(60000);

   it('should join from renata', async() => {
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
       console.log('Uport plasma', await promisify(twoKeyProtocol.plasmaWeb3.eth.getAccounts, []));
       let txHash = await twoKeyProtocol.DonationCampaign.visit(campaignAddress, links.renata);
       const hash = await twoKeyProtocol.AcquisitionCampaign.join(campaignAddress, from, {
           cut: 2,
           referralLink: links.renata
       });
       console.log('Uport offchain REFLINK', hash);
       links.uport = hash;
   }).timeout(60000);


   it('should visit before donate', async() => {
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
       let txHash = await twoKeyProtocol.DonationCampaign.visit(campaignAddress, links.uport);
       console.log(txHash);
   }).timeout(60000);

   it('should join and donate', async () => {
       let txHash = await twoKeyProtocol.DonationCampaign.joinAndConvert(campaignAddress, twoKeyProtocol.Utils.toWei(10*minDonationAmount, 'ether'), links.uport, from);
       console.log(txHash);
       await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
       expect(txHash).to.be.a('string');
   }).timeout(60000);


    it('should get donation', async() => {
        let donation = await twoKeyProtocol.DonationCampaign.getDonation(campaignAddress,0,from);
        console.log(donation);
    }).timeout(60000);

    it('should get referrers to converter for conversions', async() => {
        let referrersForTest4 = await twoKeyProtocol.DonationCampaign.getRefferrersToConverter(campaignAddress, env.TEST4_ADDRESS, from);
        console.log(referrersForTest4);
    }).timeout(60000);

});
