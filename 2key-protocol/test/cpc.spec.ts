import {TwoKeyProtocol} from "../src";
import {expect} from "chai";
import web3Switcher from "./helpers/web3Switcher";
import getTwoKeyProtocol, {getTwoKeyProtocolValues} from "./helpers/twoKeyProtocol";
import {TIMEOUT} from "dns";
const { env } = process;


const TIMEOUT_LENGTH = 60000;
let i = 1;
let twoKeyProtocol: TwoKeyProtocol;
let from: string;
let addressBalanceBeforeConversion;
require('es6-promise').polyfill();
require('isomorphic-fetch');
require('isomorphic-form-data');

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
    bountyPerConversionWei: 50
};

let percentageLeft = 0.98;
let campaignAddress;
let campaignPublicAddress;
let converterPlasma;
let influencers;

// 3 ETHER will be staked as rewards pool
const etherForRewards = 3;

describe('CPC campaign', () => {
    it('should create a CPC campaign', async() => {
        printTestNumber();
        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_DEPLOYER);

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

    it('should get contractor plasma and public address', async() => {
        printTestNumber();

        const addresses = await twoKeyProtocol.CPCCampaign.getContractorAddresses(campaignAddress);
        expect(addresses.contractorPlasma).to.be.equal(twoKeyProtocol.plasmaAddress);
        expect(addresses.contractorPublic).to.be.equal(from);
    }).timeout(TIMEOUT_LENGTH);


    it('should check if address is contractor', async() => {
        printTestNumber();

        let isContractor = await twoKeyProtocol.CPCCampaign.isAddressContractor(campaignPublicAddress, from);
        expect(isContractor).to.be.equal(true);
    }).timeout(TIMEOUT_LENGTH);

    it('should validate that mirroring is done well on plasma', async() => {
        printTestNumber();

        const publicMirrorOnPlasma = await twoKeyProtocol.CPCCampaign.getMirrorContractPlasma(campaignAddress);
        expect(publicMirrorOnPlasma).to.be.equal(campaignPublicAddress);
    }).timeout(TIMEOUT_LENGTH);

    it('should validate that mirroring is done well on public', async() => {
        printTestNumber();

        const plasmaMirrorOnPublic = await twoKeyProtocol.CPCCampaign.getMirrorContractPublic(campaignPublicAddress);
        expect(plasmaMirrorOnPublic).to.be.equal(campaignAddress);
    }).timeout(TIMEOUT_LENGTH);


    it('should get private meta hash', async() => {
        printTestNumber();

        let privateMeta = await twoKeyProtocol.CPCCampaign.getPrivateMetaHash(campaignAddress, twoKeyProtocol.plasmaAddress);
        expect(privateMeta.campaignPublicLinkKey).to.be.equal(links.deployer.link);
    }).timeout(TIMEOUT_LENGTH);

    it('should buy referral rewards on public contract by sending ether', async() => {
        printTestNumber();
        let txHash = await twoKeyProtocol.CPCCampaign.buyTokensForReferralRewards(campaignAddress, twoKeyProtocol.Utils.toWei(etherForRewards, 'ether'), from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);


    it('should show the rate of 2key at the moment bought and the amount of tokens in the inventory received', async() => {
        printTestNumber();
        let amountOfTokensReceived = await twoKeyProtocol.CPCCampaign.getInitialBountyAmount(campaignPublicAddress);

        let boughtRate = await twoKeyProtocol.CPCCampaign.getBought2keyRate(campaignAddress);
        let eth2usd = await twoKeyProtocol.TwoKeyExchangeContract.getBaseToTargetRate("USD");
        expect(amountOfTokensReceived*boughtRate).to.be.equal(etherForRewards*eth2usd);
    }).timeout(TIMEOUT_LENGTH);


    it('should set that plasma contract is valid from maintainer', async() => {
        printTestNumber();

        const {web3, address} = web3Switcher.buyer();
        from = address;
        twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_BUYER);
        let txHash = await twoKeyProtocol.CPCCampaign.validatePlasmaContract(campaignAddress, twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);


    it('should set on plasma contract inventory amount from maintainer', async() => {
        printTestNumber();
        let amountOfTokensAdded = await twoKeyProtocol.CPCCampaign.getInitialBountyAmount(campaignPublicAddress);
        let maxNumberOfConversions = Math.floor(amountOfTokensAdded / parseFloat(twoKeyProtocol.Utils.fromWei(campaignObject.bountyPerConversionWei,'ether').toString()));
        let txHash = await twoKeyProtocol.CPCCampaign.setTotalBountyPlasma(campaignAddress, twoKeyProtocol.Utils.toWei(amountOfTokensAdded,'ether'), maxNumberOfConversions, twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);

    it('should set that public contract is valid from maintainer', async() => {
        printTestNumber();

        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));

        let txHash = await twoKeyProtocol.CPCCampaign.validatePublicContract(campaignAddress, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);

    it('should get max number of conversions', async() => {
        printTestNumber();
        let maxNumberOfConversions = await twoKeyProtocol.CPCCampaign.getMaxNumberOfConversions(campaignAddress);
        console.log(maxNumberOfConversions);
        expect(maxNumberOfConversions).to.be.equal(100);
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

        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_DEPLOYER));

        const pkl = await twoKeyProtocol.CPCCampaign.getPublicLinkKey(campaignAddress, twoKeyProtocol.plasmaAddress);
        expect(pkl.length).to.be.greaterThan(0);
    }).timeout(TIMEOUT_LENGTH);

    it('should visit and join campaign from test user', async() => {
        printTestNumber();

        const {web3, address} = web3Switcher.test();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_TEST));
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
        const {web3, address} = web3Switcher.gmail();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_GMAIL));

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

        const {web3, address} = web3Switcher.test4();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_TEST4));

        let txHash = await twoKeyProtocol.CPCCampaign.visit(campaignAddress, links.gmail.link, links.gmail.fSecret);
    }).timeout(TIMEOUT_LENGTH);

    it('should convert', async() => {
        printTestNumber();
        converterPlasma = twoKeyProtocol.plasmaAddress;
        let txHash = await twoKeyProtocol.CPCCampaign.joinAndConvert(campaignAddress, links.gmail.link, twoKeyProtocol.plasmaAddress, {fSecret: links.gmail.fSecret});
        console.log(txHash);
    }).timeout(TIMEOUT_LENGTH);

    it('should get active influencers before conversion is approved', async() => {
        printTestNumber();

        let activeInfluencers = await twoKeyProtocol.CPCCampaign.getActiveInfluencers(campaignAddress);
        expect(activeInfluencers.length).to.be.equal(0);
    }).timeout(TIMEOUT_LENGTH);


    it('should approve converter from maintainer and distribute rewards', async() => {
        printTestNumber();
        // Long functions take time set timeout to make sure previous one is mined
        await new Promise(resolve => setTimeout(resolve, 5000));
        const {web3, address} = web3Switcher.buyer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_BUYER));

        let txHash = await twoKeyProtocol.CPCCampaign.approveConverterAndExecuteConversion(campaignAddress, converterPlasma, twoKeyProtocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);


    it('should get number of influencers behind converter', async() => {
        printTestNumber();
        // Long functions take time set timeout to make sure previous one is mined
        await new Promise(resolve => setTimeout(resolve, 5000));
        let numberOfReferrers = await twoKeyProtocol.CPCCampaign.getNumberOfInfluencersForConverter(campaignAddress, converterPlasma);
        expect(numberOfReferrers).to.be.equal(2);
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

        expect(balanceA).to.be.equal(25 * percentageLeft);
    }).timeout(TIMEOUT_LENGTH);


    it('should get conversion object from the plasma chain', async() => {
        printTestNumber();

        let conversion = await twoKeyProtocol.CPCCampaign.getConversion(campaignAddress, 0);
        expect(conversion.converterPlasma).to.be.equal(converterPlasma);
        expect(conversion.conversionState).to.be.equal("EXECUTED");
        expect(conversion.bountyPaid).to.be.equal(parseFloat(twoKeyProtocol.Utils.fromWei(campaignObject.bountyPerConversionWei, 'ether').toString())*percentageLeft);
    }).timeout(TIMEOUT_LENGTH);


    it('should get active influencers', async() => {
        printTestNumber();

        let activeInfluencers = await twoKeyProtocol.CPCCampaign.getActiveInfluencers(campaignAddress);
        expect(activeInfluencers.length).to.be.equal(2);
    }).timeout(TIMEOUT_LENGTH);

    it('should test if influencers are joined', async() => {
        printTestNumber();
        let activeInfluencers = await twoKeyProtocol.CPCCampaign.getActiveInfluencers(campaignAddress);
        let isJoined = await twoKeyProtocol.CPCCampaign.isAddressJoined(campaignAddress, activeInfluencers[0]);
        expect(isJoined).to.be.equal(true);
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


    // it('should get merklee proof from roots as an influencer', async() => {
    //     printTestNumber();
    //
    //     const {web3, address} = web3Switcher.test();
    //     from = address;
    //     twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_TEST));
    //
    //     let proofs = await twoKeyProtocol.CPCCampaign.getMerkleProofFromRoots(campaignAddress, twoKeyProtocol.plasmaAddress);
    //     expect(proofs.length).to.be.greaterThan(0);
    // }).timeout(TIMEOUT_LENGTH);
    //
    // it('should check merkle proof on the main chain from influencer address', async() => {
    //     printTestNumber();
    //     let isProofValid = await twoKeyProtocol.CPCCampaign.checkMerkleProofAsInfluencer(campaignAddress, twoKeyProtocol.plasmaAddress);
    //     expect(isProofValid).to.be.equal(true);
    // }).timeout(TIMEOUT_LENGTH);

    // it('should withdraw more than he earned tokens as an influencer with his proof', async() => {
    //     printTestNumber();
    //     let influencerEarnings = await twoKeyProtocol.CPCCampaign.getReferrerBalance(campaignAddress, twoKeyProtocol.plasmaAddress);
    //     let proofs = await twoKeyProtocol.CPCCampaign.getMerkleProofFromRoots(campaignAddress, twoKeyProtocol.plasmaAddress);
    //     influencerEarnings = influencerEarnings + "0";
    //     try {
    //         let txHash = await twoKeyProtocol.CPCCampaign.submitProofAndWithdrawRewards(campaignAddress, proofs, influencerEarnings, from);
    //     } catch (e) {
    //         expect(1).to.be.equal(1);
    //     }
    // }).timeout(TIMEOUT_LENGTH);
    //
    // it('should try to withdraw valid amount of tokens', async() => {
    //     printTestNumber();
    //     let influencerEarnings = await twoKeyProtocol.CPCCampaign.getReferrerBalance(campaignAddress, twoKeyProtocol.plasmaAddress);
    //     let proofs = await twoKeyProtocol.CPCCampaign.getMerkleProofFromRoots(campaignAddress, twoKeyProtocol.plasmaAddress);
    //     addressBalanceBeforeConversion = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyProtocol.twoKeyEconomy.address, from);
    //     addressBalanceBeforeConversion = parseInt(addressBalanceBeforeConversion,10);
    //     let txHash = await twoKeyProtocol.CPCCampaign.submitProofAndWithdrawRewards(campaignAddress, proofs, influencerEarnings, from);
    //     await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    // }).timeout(TIMEOUT_LENGTH);


    it('should push balances for influencers to the mainchain', async() => {
        printTestNumber();

        // Deployer is the maintainer address
        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_TEST));

        let numberOfInfluencers = await twoKeyProtocol.CPCCampaign.getNumberOfActiveInfluencers(campaignAddress);
        let resp = await twoKeyProtocol.CPCCampaign.getInfluencersAndBalances(campaignAddress, 0, numberOfInfluencers);
        resp.balances = resp.balances.map(balance => twoKeyProtocol.Utils.toWei(balance,'ether'));
        let txHash = await twoKeyProtocol.CPCCampaign.pushBalancesForInfluencers(campaignPublicAddress,resp.influencers, resp.balances, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);

    it('should get reserved amount of rewards', async() => {
        printTestNumber();
        let rewards = await twoKeyProtocol.CPCCampaign.getReservedAmountForRewards(campaignPublicAddress);
        console.log(rewards);
    }).timeout(TIMEOUT_LENGTH);


    it('should distribute rewards between influencers on the mainchain', async() => {
        printTestNumber();
        let numberOfInfluencers = await twoKeyProtocol.CPCCampaign.getNumberOfActiveInfluencers(campaignAddress);
        let resp = await twoKeyProtocol.CPCCampaign.getInfluencersAndBalances(campaignAddress, 0, numberOfInfluencers);
        console.log(resp);
        let txHash = await twoKeyProtocol.CPCCampaign.distributeRewardsBetweenInfluencers(campaignPublicAddress, resp.influencers, from);
        await twoKeyProtocol.Utils.getTransactionReceiptMined(txHash);
    }).timeout(TIMEOUT_LENGTH);

    it('should get counters from the campaign', async() => {
        printTestNumber();

        let counters = await twoKeyProtocol.CPCCampaign.getCampaignSummary(campaignAddress);
        expect(counters.totalBounty).to.be.equal(50*percentageLeft);
    }).timeout(TIMEOUT_LENGTH);

    it('should get number of forwarders for the campaign', async() => {
        printTestNumber();

        let numberOfForwarders = await twoKeyProtocol.PlasmaEvents.getForwardersPerCampaign(campaignAddress);
        expect(numberOfForwarders).to.be.equal(2);
    }).timeout(TIMEOUT_LENGTH);


    it('should get address stats', async() => {
        printTestNumber();

        const {web3, address} = web3Switcher.test();
        from = address;
        twoKeyProtocol.setWeb3(getTwoKeyProtocolValues(web3, env.MNEMONIC_TEST));

        let stats = await twoKeyProtocol.CPCCampaign.getAddressStatistic(campaignAddress, twoKeyProtocol.plasmaAddress);
        expect(stats.ethereum).to.be.equal(from);
        expect(stats.username).to.be.equal('test');
    }).timeout(TIMEOUT_LENGTH);

    it('should print number of active influencers and get referrers and earnings', async() => {
        printTestNumber();
        let numberOfActiveInfluencers = await twoKeyProtocol.CPCCampaign.getNumberOfActiveInfluencers(campaignAddress);
        let obj = await twoKeyProtocol.CPCCampaign.getInfluencersAndBalances(campaignAddress, 0, numberOfActiveInfluencers);
        console.log(obj);
        expect(obj.influencers.length).to.be.equal(numberOfActiveInfluencers);
    }).timeout(TIMEOUT_LENGTH);

    it('should get moderator earnings per campaign', async() => {
        printTestNumber();
        let moderatorEarnings = await twoKeyProtocol.CPCCampaign.getModeratorEarningsPerCampaign(campaignAddress);
        expect(moderatorEarnings).to.be.equal(parseFloat(twoKeyProtocol.Utils.fromWei(campaignObject.bountyPerConversionWei,'ether').toString())* 0.02);
    }).timeout(TIMEOUT_LENGTH);

    it('should contractor withdraw unspent budget', async() => {
        const {web3, address} = web3Switcher.deployer();
        from = address;
        twoKeyProtocol = getTwoKeyProtocol(web3, env.MNEMONIC_DEPLOYER);

        printTestNumber();
        let campaignBalanceBefore = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyProtocol.twoKeyEconomy.address, campaignPublicAddress);
        let contractorBalanceBefore = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyProtocol.twoKeyEconomy.address, address);
        console.log(campaignBalanceBefore);

        let txHash = await twoKeyProtocol.CPCCampaign.contractorWithdraw(campaignPublicAddress, from);
        await new Promise(resolve => setTimeout(resolve, 5000));

        let contractorBalanceAfter = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyProtocol.twoKeyEconomy.address, address);

        console.log(contractorBalanceBefore,contractorBalanceAfter);
        let campaignBalanceAfter = await twoKeyProtocol.ERC20.getERC20Balance(twoKeyProtocol.twoKeyEconomy.address, campaignPublicAddress);
        console.log(campaignBalanceAfter);
    }).timeout(TIMEOUT_LENGTH)


});
