import {TwoKeyProtocol} from "../src";
import singletons from "../src/contracts/singletons";
import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {expect} from "chai";
import {promisify} from "../src/utils/promisify";
const { env } = process;

const rpcUrl = env.RPC_URL;
const mainNetId = env.MAIN_NET_ID;
const syncTwoKeyNetId = env.SYNC_NET_ID;
const eventsNetUrl = env.PLASMA_RPC_URL;

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
    url: "nikola@gmail.com",
    moderator: "",
    incentiveModel: "VANILLA_AVERAGE",
    campaignStartTime : 0,
    campaignEndTime : 9884748832,
    maxReferralRewardPercent: 20
};

let campaignAddress;
let campaignPublicAddress;
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

        console.log(result);
    }).timeout(60000);

    it('should validate mirroring on plasma', async() => {
        printTestNumber();

        const publicMirrorOnPlasma = await twoKeyProtocol.TwoKeyCPCCampaign.getMirrorContractPlasma(campaignAddress);
        expect(publicMirrorOnPlasma).to.be.equal(campaignPublicAddress);
    }).timeout(60000);

    it('should validate mirroring on public', async() => {
        printTestNumber();

        const plasmaMirrorOnPublic = await twoKeyProtocol.TwoKeyCPCCampaign.getMirrorContractPublic(campaignPublicAddress);
        expect(plasmaMirrorOnPublic).to.be.equal(campaignAddress);
    }).timeout(60000);

    it('should set that plasma contract is valid from maintainer', async() => {
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
    }).timeout(60000);

    it('should get campaign from IPFS', async () => {
        printTestNumber();

        const campaignMeta = await twoKeyProtocol.TwoKeyCPCCampaign.getPublicMeta(campaignAddress,twoKeyProtocol.plasmaAddress);
        expect(campaignMeta.meta.url).to.be.equal(campaignObject.url);
    }).timeout(60000);

    it('should get public link key of contractor', async() => {
        printTestNumber();

        const pkl = await twoKeyProtocol.TwoKeyCPCCampaign.getPublicLinkKey(campaignAddress, twoKeyProtocol.plasmaAddress);
        console.log(pkl);
    }).timeout(60000);

    it('should visit campaign from guest', async() => {
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
        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.visit(campaignAddress, links.deployer.link, links.deployer.fSecret);
        console.log(txHash);
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

        let txHash = await twoKeyProtocol.TwoKeyCPCCampaign.visit(campaignAddress, links.deployer.link, links.deployer.fSecret);
        const hash = await twoKeyProtocol.TwoKeyCPCCampaign.join(campaignAddress, twoKeyProtocol.plasmaAddress, {
            cut: 50,
            referralLink: links.deployer.link,
            fSecret: links.deployer.fSecret,
        });
        links.gmail = hash;

        console.log('Gmail link is: ' + links.gmail.link);
        expect(links.gmail.link).to.be.a('string');
    }).timeout(60000);

});
