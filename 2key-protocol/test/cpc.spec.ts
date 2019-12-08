import {TwoKeyProtocol} from "../src";
import singletons from "../src/contracts/singletons";
import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {expect} from "chai";
import {promisify} from "../src/utils/promisify";
import {IPrivateMetaInformation} from "../src/acquisition/interfaces";
const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const eventsNetUrl = env.PLASMA_RPC_URL;

const TIMEOUT_LENGTH = 60000;
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
    buyer: () => createWeb3(env.MNEMONIC_BUYER, rpcUrl)
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
    maxReferralRewardPercent: 20,
    bountyPerConversion: 3
};

let campaignAddress;
let campaignPublicAddress;
let converterPlasma;

// 3 ETHER will be staked as rewards pool
const etherForRewards = 3;

describe('CPC campaign', () => {

    it('should create a CPC campaign', async() => {
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


        let result = await twoKeyProtocol.TwoKeyCPCCampaign.createCPCCampaign(campaignObject, campaignObject, {}, twoKeyProtocol.plasmaAddress, from, {
            progressCallback,
            gasPrice: 150000000000,
            interval: 500,
            timeout: 600000
        });

        campaignPublicAddress = result.campaignAddressPublic;
        campaignAddress = result.campaignAddress;

        links.deployer = { link: result.campaignPublicLinkKey, fSecret: result.fSecret };
        campaignAddress = result.campaignAddress;
    }).timeout(TIMEOUT_LENGTH);

    it('should validate that mirroring is done well on plasma', async() => {
        printTestNumber();

        const publicMirrorOnPlasma = await twoKeyProtocol.TwoKeyCPCCampaign.getMirrorContractPlasma(campaignAddress);
        expect(publicMirrorOnPlasma).to.be.equal(campaignPublicAddress);
    }).timeout(TIMEOUT_LENGTH);

    it('should validate that mirroring is done well on public', async() => {
        printTestNumber();

        const plasmaMirrorOnPublic = await twoKeyProtocol.TwoKeyCPCCampaign.getMirrorContractPublic(campaignPublicAddress);
        expect(plasmaMirrorOnPublic).to.be.equal(campaignAddress);
    }).timeout(TIMEOUT_LENGTH);


    it('should buy referral rewards on public contract by sending ether', async() => {
        printTestNumber();
        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.buyTokensForReferralRewards(campaignPublicAddress, twoKeyProtocol.Utils.toWei(etherForRewards, 'ether'), from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);


    it('should show the rate of 2key at the moment bought and the amount of tokens in the inventory received', async() => {
        printTestNumber();
        let amountOfTokensReceived = await twoKeyProtocol.TwoKeyCPCCampaign.getTokensAvailableInInventory(campaignPublicAddress);

        let boughtRate = await twoKeyProtocol.TwoKeyCPCCampaign.getBought2keyRate(campaignPublicAddress);
        let eth2usd = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate("USD");

        expect(amountOfTokensReceived*boughtRate).to.be.equal(etherForRewards*eth2usd);
    }).timeout(TIMEOUT_LENGTH);


    it('should set that plasma contract is valid from maintainer', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.buyer();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_BUYER).privateKey,
        });
        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.validatePlasmaContract(campaignAddress, twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);

    it('should set that public contract is valid from maintainer', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_DEPLOYER).privateKey,
        });

        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.validatePublicContract(campaignPublicAddress, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);

    it('should proof that plasma contract is validated well from maintainer side', async() => {
        printTestNumber();
        let isContractValid = await twoKeyProtocol.TwoKeyCPCCampaign.checkIsPlasmaContractValid(campaignAddress);
        expect(isContractValid).to.be.equal(true);
    }).timeout(TIMEOUT_LENGTH);

    it('should proof that public contract is validated well from maintainer side', async() => {
        printTestNumber();
        let isContractValid = await twoKeyProtocol.TwoKeyCPCCampaign.checkIsPublicContractValid(campaignPublicAddress);
        expect(isContractValid).to.be.equal(true);
    }).timeout(TIMEOUT_LENGTH);

    it('should get campaign from IPFS', async () => {
        printTestNumber();

        const campaignMeta = await twoKeyProtocol.TwoKeyCPCCampaign.getPublicMeta(campaignAddress,twoKeyProtocol.plasmaAddress);
        expect(campaignMeta.meta.url).to.be.equal(campaignObject.url);
    }).timeout(TIMEOUT_LENGTH);

    it('should get public link key of contractor', async() => {
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

        const pkl = await twoKeyProtocol.TwoKeyCPCCampaign.getPublicLinkKey(campaignAddress, twoKeyProtocol.plasmaAddress);
        expect(pkl.length).to.be.greaterThan(0);
    }).timeout(TIMEOUT_LENGTH);

    it('should visit and join campaign from test user', async() => {
        printTestNumber();

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
        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.visit(campaignAddress, links.deployer.link, links.deployer.fSecret);

        const hash = await twoKeyProtocol.TwoKeyCPCCampaign.join(campaignAddress, twoKeyProtocol.plasmaAddress, {
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
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_GMAIL).privateKey,
        });

        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.visit(campaignAddress, links.test.link, links.test.fSecret);
        const hash = await twoKeyProtocol.TwoKeyCPCCampaign.join(campaignAddress, twoKeyProtocol.plasmaAddress, {
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
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_TEST4).privateKey,
        });

        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.visit(campaignAddress, links.gmail.link, links.gmail.fSecret);
    }).timeout(TIMEOUT_LENGTH);


    it('should convert', async() => {
        printTestNumber();
        converterPlasma = twoKeyProtocol.plasmaAddress;
        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.joinAndConvert(campaignAddress, links.gmail.link, twoKeyProtocol.plasmaAddress, {fSecret: links.gmail.fSecret});
    }).timeout(TIMEOUT_LENGTH);

    it('should get both influencers involved in conversion from plasma contract', async() => {
        printTestNumber();
        let influencers = await twoKeyProtocol.TwoKeyCPCCampaign.getReferrers(campaignAddress, twoKeyProtocol.plasmaAddress);
        expect(influencers.length).to.be.equal(2);
    }).timeout(TIMEOUT_LENGTH);

    it('should approve converter from maintainer and distribute rewards', async() => {
        printTestNumber();

        const {web3, address} = web3switcher.buyer();
        from = address;
        twoKeyProtocol.setWeb3({
            web3,
            networks: {
                mainNetId,
                syncTwoKeyNetId,
            },
            eventsNetUrl,
            plasmaPK: generatePlasmaFromMnemonic(env.MNEMONIC_BUYER).privateKey,
        });
        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.approveConverterAndExecuteConversion(campaignAddress, converterPlasma, twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);

});
