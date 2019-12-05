import {TwoKeyProtocol} from "../src";
import singletons from "../src/contracts/singletons";
import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {expect} from "chai";
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


        let result = await twoKeyProtocol.TwoKeyPlasmaCPCCampaign.createPlasma(campaignObject, campaignObject, {}, twoKeyProtocol.plasmaAddress , {
            progressCallback,
            gasPrice: 150000000000,
            interval: 500,
            timeout: 600000
        });

        campaignAddress = result.campaignAddress;
        console.log(campaignAddress);

        console.log(result);
    }).timeout(60000);


    it('should get campaign from IPFS', async () => {
        printTestNumber();

        const campaignMeta = await twoKeyProtocol.TwoKeyPlasmaCPCCampaign.getPublicMeta(campaignAddress,twoKeyProtocol.plasmaAddress);
        console.log(campaignMeta);
    }).timeout(120000);

    it('should get public link key of contractor', async() => {
        printTestNumber();

        const pkl = await twoKeyProtocol.TwoKeyPlasmaCPCCampaign.getPublicLinkKey(campaignAddress, twoKeyProtocol.plasmaAddress);
        console.log(pkl);
    })
});
