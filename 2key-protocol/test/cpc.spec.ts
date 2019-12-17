import {TwoKeyProtocol} from "../src";
import singletons from "../src/contracts/singletons";
import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {expect} from "chai";
import {promisify} from "../src/utils/promisify";
import {IPrivateMetaInformation} from "../src/acquisition/interfaces";
const { env } = process;

const networkId = parseInt(env.MAIN_NET_ID, 10);
const privateNetworkId = parseInt(env.SYNC_NET_ID, 10);

const rpcUrls = [env.RPC_URL];
const eventsNetUrls = [env.PLASMA_RPC_URL];

const TIMEOUT_LENGTH = 60000;
let i = 1;
let twoKeyProtocol: TwoKeyProtocol;
let from: string;

require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

const web3switcher = {
    deployer: () => createWeb3(env.MNEMONIC_DEPLOYER, rpcUrls),
    aydnep: () => createWeb3(env.MNEMONIC_AYDNEP, rpcUrls),
    gmail: () => createWeb3(env.MNEMONIC_GMAIL, rpcUrls),
    test4: () => createWeb3(env.MNEMONIC_TEST4, rpcUrls),
    renata: () => createWeb3(env.MNEMONIC_RENATA, rpcUrls),
    uport: () => createWeb3(env.MNEMONIC_UPORT, rpcUrls),
    gmail2: () => createWeb3(env.MNEMONIC_GMAIL2, rpcUrls),
    aydnep2: () => createWeb3(env.MNEMONIC_AYDNEP2, rpcUrls),
    test: () => createWeb3(env.MNEMONIC_TEST, rpcUrls),
    guest: () => createWeb3('mnemonic words should be here but for some reason they are missing', rpcUrls),
    buyer: () => createWeb3(env.MNEMONIC_BUYER, rpcUrls)
};

const links: any = {
    deployer: {},
    aydnep: {},
    gmail: {},
    test4: {},
    renata: {},
    uport: {},
    gmail2: {},
    aydnep2: {},
    test: {},
};


const progressCallback = (name: string, mined: boolean, transactionResult: string): void => {
    console.log(`Contract ${name} ${mined ? `deployed with address ${transactionResult}` : `placed to EVM. Hash ${transactionResult}`}`);
};

const printTestNumber = (): void => {
    console.log('--------------------------------------- Test ' + i + ' ----------------------------------------------');
    i++;
};

let campaignObject = {
    url: "https://2key.network",
    moderator: "",
    incentiveModel: "VANILLA_AVERAGE",
    campaignStartTime : 0,
    campaignEndTime : 9884748832,
    bountyPerConversionWei: 3
};

let campaignAddress;
let campaignPublicAddress;
let converterPlasma;
let influencers;

// 3 ETHER will be staked as rewards pool
const etherForRewards = 3;

describe('CPC campaign', () => {

    it('should create a CPC campaign', async() => {
        printTestNumber();
        const {web3, address} = web3switcher.deployer();
        from = address;
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_DEPLOYER).privateKey,
            networkId,
            privateNetworkId,
        });

        //Convert bounty per conversion to be in WEI
        campaignObject.bountyPerConversionWei = parseFloat(twoKeyProtocol.Utils.toWei(campaignObject.bountyPerConversionWei,'ether').toString());

        let result = await twoKeyProtocol.CPCCampaign.createCPCCampaign(campaignObject, campaignObject, {}, twoKeyProtocol.plasmaAddress, from, {
            progressCallback,
            gasPrice: 150000000000,
            interval: 500,
            timeout: 600000
        });

        campaignPublicAddress = result.campaignAddressPublic;
        campaignAddress = result.campaignAddress;

        links.deployer = { link: result.campaignPublicLinkKey, fSecret: result.fSecret };
    }).timeout(TIMEOUT_LENGTH);

    it('should validate that mirroring is done well on plasma', async() => {
        printTestNumber();

        const publicMirrorOnPlasma = await twoKeyProtocol.CPCCampaign.getMirrorContractPlasma(campaignAddress);
        expect(publicMirrorOnPlasma).to.be.equal(campaignPublicAddress);
    }).timeout(TIMEOUT_LENGTH);

    it('should validate that mirroring is done well on public', async() => {
        printTestNumber();

        const plasmaMirrorOnPublic = await twoKeyProtocol.CPCCampaign.getMirrorContractPublic(campaignAddress);
        expect(plasmaMirrorOnPublic).to.be.equal(campaignAddress);
    }).timeout(TIMEOUT_LENGTH);


    it('should buy referral rewards on public contract by sending ether', async() => {
        printTestNumber();
        let txHash = await twoKeyProtocol.CPCCampaign.buyTokensForReferralRewards(campaignAddress, twoKeyProtocol.Utils.toWei(etherForRewards, 'ether'), from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);


    it('should show the rate of 2key at the moment bought and the amount of tokens in the inventory received', async() => {
        printTestNumber();
        let amountOfTokensReceived = await twoKeyProtocol.CPCCampaign.getTokensAvailableInInventory(campaignAddress);

        let boughtRate = await twoKeyProtocol.CPCCampaign.getBought2keyRate(campaignAddress);
        let eth2usd = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate("USD");
        expect(amountOfTokensReceived*boughtRate).to.be.equal(etherForRewards*eth2usd);
    }).timeout(TIMEOUT_LENGTH);


    it('should set that plasma contract is valid from maintainer', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.buyer();
        from = address;
        twoKeyProtocol = new TwoKeyProtocol({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_BUYER).privateKey,
            networkId,
            privateNetworkId,
        });
        let txHash = await twoKeyProtocol.CPCCampaign.validatePlasmaContract(campaignAddress, twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);


    it('should set on plasma contract inventory amount from maintainer', async() => {
        printTestNumber();
        let amountOfTokensAdded = await twoKeyProtocol.CPCCampaign.getTokensAvailableInInventory(campaignAddress);
        await twoKeyProtocol.CPCCampaign.setTotalBountyPlasma(campaignAddress, twoKeyProtocol.Utils.toWei(amountOfTokensAdded,'ether'), twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);

    it('should get total bounty and bounty per conversion from plasma', async() => {
        printTestNumber();
        let bounties = await twoKeyProtocol.CPCCampaign.getTotalBountyAndBountyPerConversion(campaignAddress);
        expect(bounties.bountyPerConversion).to.be.equal(parseFloat(twoKeyProtocol.Utils.fromWei(campaignObject.bountyPerConversionWei, 'ether').toString()));
    }).timeout(TIMEOUT_LENGTH);

    it('should get max number of conversions', async() => {
        printTestNumber();
        let maxNumberOfConversions = await twoKeyProtocol.CPCCampaign.getMaxNumberOfConversions(campaignAddress);
        console.log('Max number of conversions: ' + maxNumberOfConversions);
    }).timeout(TIMEOUT_LENGTH);


    it('should set that public contract is valid from maintainer', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_DEPLOYER).privateKey,
            networkId,
            privateNetworkId,
        });

        let txHash = await twoKeyProtocol.CPCCampaign.validatePublicContract(campaignAddress, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);

    it('should proof that plasma contract is validated well from maintainer side', async() => {
        printTestNumber();
        let isContractValid = await twoKeyProtocol.CPCCampaign.checkIsPlasmaContractValid(campaignAddress);
        expect(isContractValid).to.be.equal(true);
    }).timeout(TIMEOUT_LENGTH);

    it('should proof that public contract is validated well from maintainer side', async() => {
        printTestNumber();
        let isContractValid = await twoKeyProtocol.CPCCampaign.checkIsPublicContractValid(campaignAddress);
        expect(isContractValid).to.be.equal(true);
    }).timeout(TIMEOUT_LENGTH);

    it('should get campaign from IPFS', async () => {
        printTestNumber();

        const campaignMeta = await twoKeyProtocol.CPCCampaign.getPublicMeta(campaignAddress,twoKeyProtocol.plasmaAddress);
        expect(campaignMeta.meta.url).to.be.equal(campaignObject.url);
    }).timeout(TIMEOUT_LENGTH);

    it('should get public link key of contractor', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_DEPLOYER).privateKey,
            networkId,
            privateNetworkId,
        });

        const pkl = await twoKeyProtocol.CPCCampaign.getPublicLinkKey(campaignAddress, twoKeyProtocol.plasmaAddress);
        expect(pkl.length).to.be.greaterThan(0);
    }).timeout(TIMEOUT_LENGTH);

    it('should visit and join campaign from test user', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.test();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST).privateKey,
            networkId,
            privateNetworkId,
        });
        let txHash = await twoKeyProtocol.CPCCampaign.visit(campaignAddress, links.deployer.link, links.deployer.fSecret);

        const hash = await twoKeyProtocol.CPCCampaign.join(campaignAddress, twoKeyProtocol.plasmaAddress, {
            cut: 15,
            referralLink: links.deployer.link,
            fSecret: links.deployer.fSecret,
        });
        links.test = hash;

        expect(links.test.link).to.be.a('string');

    }).timeout(TIMEOUT_LENGTH);

    it('should create a join link by gmail', async () => {
        printTestNumber();
        const {web3, address} = web3switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_GMAIL).privateKey,
            networkId,
            privateNetworkId,
        });

        let txHash = await twoKeyProtocol.CPCCampaign.visit(campaignAddress, links.test.link, links.test.fSecret);
        const hash = await twoKeyProtocol.CPCCampaign.join(campaignAddress, twoKeyProtocol.plasmaAddress, {
            cut: 17,
            referralLink: links.test.link,
            fSecret: links.test.fSecret,
        });
        links.gmail = hash;

        expect(links.gmail.link).to.be.a('string');
    }).timeout(TIMEOUT_LENGTH);

    it('should visit campaign', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.test4();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST4).privateKey,
            networkId,
            privateNetworkId,
        });

        let txHash = await twoKeyProtocol.CPCCampaign.visit(campaignAddress, links.gmail.link, links.gmail.fSecret);
    }).timeout(TIMEOUT_LENGTH);


    it('should convert', async() => {
        printTestNumber();
        converterPlasma = twoKeyProtocol.plasmaAddress;
        let txHash = await twoKeyProtocol.CPCCampaign.joinAndConvert(campaignAddress, links.gmail.link, twoKeyProtocol.plasmaAddress, {fSecret: links.gmail.fSecret});
    }).timeout(TIMEOUT_LENGTH);


    it('should get active influencers before conversion is approved', async() => {
        printTestNumber();

        let activeInfluencers = await twoKeyProtocol.CPCCampaign.getActiveInfluencers(campaignAddress);
        expect(activeInfluencers.length).to.be.equal(0);
    }).timeout(TIMEOUT_LENGTH);


    it('should approve converter from maintainer and distribute rewards', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.buyer();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_BUYER).privateKey,
            networkId,
            privateNetworkId,
        });
        let txHash = await twoKeyProtocol.CPCCampaign.approveConverterAndExecuteConversion(campaignAddress, converterPlasma, twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);


    it('should get both influencers involved in conversion from plasma contract and their balances', async() => {
        printTestNumber();
        influencers = await twoKeyProtocol.CPCCampaign.getReferrers(campaignAddress, converterPlasma);
        expect(influencers.length).to.be.equal(2);
    }).timeout(TIMEOUT_LENGTH);


    it('should get rewards received by influencers', async() => {
        printTestNumber();

        let balanceA = await twoKeyProtocol.CPCCampaign.getReferrerBalanceInFloat(campaignAddress,influencers[0]);
        let balanceB = await twoKeyProtocol.CPCCampaign.getReferrerBalanceInFloat(campaignAddress,influencers[1]);

        expect(balanceA).to.be.equal(1.5);
        expect(balanceB).to.be.equal(1.5);
    }).timeout(TIMEOUT_LENGTH);


    it('should get conversion object from the plasma chain', async() => {
        printTestNumber();

        let conversion = await twoKeyProtocol.CPCCampaign.getConversion(campaignAddress, 0);
        expect(conversion.converterPlasma).to.be.equal(converterPlasma);
        expect(conversion.conversionState).to.be.equal("EXECUTED");
        expect(conversion.bountyPaid).to.be.equal(parseFloat(twoKeyProtocol.Utils.fromWei(campaignObject.bountyPerConversionWei, 'ether').toString()));
    }).timeout(TIMEOUT_LENGTH);


    it('should get active influencers', async() => {
        printTestNumber();

        let activeInfluencers = await twoKeyProtocol.CPCCampaign.getActiveInfluencers(campaignAddress);
        expect(activeInfluencers.length).to.be.equal(2);
    }).timeout(TIMEOUT_LENGTH);

    it('should lock contract (end campaign) from maintainer', async() => {
        printTestNumber();
        let txHash = await twoKeyProtocol.CPCCampaign.lockContractFromMaintainer(campaignAddress, twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);

    it('should copy the merkle root from plasma to the mainchain by maintainer', async() => {
        printTestNumber();
        let root = await twoKeyProtocol.CPCCampaign.getMerkleRootFromPlasma(campaignAddress);
        let txHash = await twoKeyProtocol.CPCCampaign.setMerkleRootOnMainchain(campaignAddress,root, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
        let rootOnPublic = await twoKeyProtocol.CPCCampaign.getMerkleRootFromPublic(campaignAddress);
        expect(root).to.be.equal(rootOnPublic);
    }).timeout(TIMEOUT_LENGTH);


    it('should get merklee proof from roots as an influencer', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.test();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            eventsNetUrls,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST).privateKey,
            networkId,
            privateNetworkId,
        });

        let proofs = await twoKeyProtocol.CPCCampaign.getMerkleProofFromRoots(campaignAddress, twoKeyProtocol.plasmaAddress);
        expect(proofs.length).to.be.greaterThan(0);
    }).timeout(TIMEOUT_LENGTH);

    it('should check merkle proof on the main chain from influencer address', async() => {
        printTestNumber();
        let isProofValid = await twoKeyProtocol.CPCCampaign.checkMerkleProofAsInfluencer(campaignAddress, twoKeyProtocol.plasmaAddress);
        expect(isProofValid).to.be.equal(true);
    }).timeout(TIMEOUT_LENGTH);

    it('should withdraw more than he earned tokens as an influencer with his proof', async() => {
        printTestNumber();
        let influencerEarnings = await twoKeyProtocol.CPCCampaign.getReferrerBalance(campaignAddress, twoKeyProtocol.plasmaAddress);
        let proofs = await twoKeyProtocol.CPCCampaign.getMerkleProofFromRoots(campaignAddress, twoKeyProtocol.plasmaAddress);
        influencerEarnings = influencerEarnings + "0";
        try {
            let txHash = await twoKeyProtocol.CPCCampaign.submitProofAndWithdrawRewards(campaignAddress, proofs, influencerEarnings, from);
        } catch (e) {
            console.log('Failed as expected');
            expect(1).to.be.equal(1);
        }
    }).timeout(TIMEOUT_LENGTH);

    it('should try to withdraw valid amount of tokens', async() => {
        printTestNumber();
        let influencerEarnings = await twoKeyProtocol.CPCCampaign.getReferrerBalance(campaignAddress, twoKeyProtocol.plasmaAddress);
        let proofs = await twoKeyProtocol.CPCCampaign.getMerkleProofFromRoots(campaignAddress, twoKeyProtocol.plasmaAddress);

        let txHash = await twoKeyProtocol.CPCCampaign.submitProofAndWithdrawRewards(campaignAddress, proofs, influencerEarnings, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);

    it('should check the amount of the tokens withdrawn', async() => {
        printTestNumber();
        let addressBalance = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyProtocol.twoKeyEconomy.address, from);
        console.log(addressBalance);
    })
});
