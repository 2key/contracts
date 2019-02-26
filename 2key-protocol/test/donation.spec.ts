import createWeb3, {generatePlasmaFromMnemonic} from "./_web3";
import {TwoKeyProtocol} from "../src";
import {expect} from "chai";
import {ICreateCampaign, InvoiceERC20} from "../src/donation/interfaces";
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

/**
 * Donation campaign parameters
 */

let campaignDescription = 'Donation for Some Services';
let publicMetaHash = 'QmABCDE';
let privateMetaHash = 'QmABCD';
let tokenName = 'Nikoloken';
let tokenSymbol = 'NTKN';
let campaignStartTime = 12345;
let campaignEndTime = 1234567;
let minDonationnAmount = 10000;
let maxDonationAmount = 10000000000000000000;
let campaignGoal = 100000000000000000000000000;
let conversionQuota = 1;
let incentiveModel = 0;



describe('TwoKeyDonationCampaign', () => {
   it('should create a donation campaign', async() => {
        let campaign: ICreateCampaign = {

        }
   }).timeout(30000);
});