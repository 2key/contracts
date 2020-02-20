import '../constants/polifils';
import availableUsers from "../constants/availableUsers";
import singletons from "../../src/contracts/singletons";
import createCampaign from "./helpers/createCampaign";
import checkCampaign from "./reusable/checkCampaign.spec";
import {expect} from "chai";
import {prepareNumberForCompare, rewardCalc} from "./helpers/numberHelpers";
import {ipfsRegex} from "../helpers/regExp";

const {env} = process;
const networkId = parseInt(env.MAIN_NET_ID, 10);


const maxConverterBonusPercent = 15;
const pricePerUnitInETHOrUSD = 0.095;
const maxReferralRewardPercent = 20;
const minContributionETHorUSD = 5;
const maxContributionETHorUSD = 1000000;
const campaignInventory = 1234000;
const campaignStartTime = 0;
const campaignEndTime = 9884748832;
const acquisitionCurrency = 'USD';
const twoKeyEconomy = singletons.TwoKeyEconomy.networks[networkId].address;
const isFiatOnly = false;
const isFiatConversionAutomaticallyApproved = true;
const vestingAmount = 'BONUS';
const isKYCRequired = true;
const incentiveModel = "MANUAL";
const amount = 0;

const {protocol: deployerProtocol} = availableUsers.deployer;
const campaignData = {
  // helper data
  campaignInventory,
  amount,
  // Probably deploer address
  moderator: availableUsers.aydnep.web3.address,
  expiryConversion: 0, // For conversion cancellation from converter side
  // twoKeyEconomy or custom erc
  assetContractERC20: twoKeyEconomy,
  pricePerUnitInETHWei: deployerProtocol.Utils.toWei(pricePerUnitInETHOrUSD, 'ether'),
  currency: acquisitionCurrency, // ETH or USD (exchange contract working)
  // Start campaign details step

  // Campaign Goals
  campaignHardCapWEI: deployerProtocol.Utils.toWei((campaignInventory * pricePerUnitInETHOrUSD), 'ether'),
  campaignSoftCapWEI: deployerProtocol.Utils.toWei((campaignInventory * pricePerUnitInETHOrUSD), 'ether'),

  // End the contract once it reaches it's goal
  endCampaignWhenHardCapReached: true,

  // Campaign Bonus
  maxConverterBonusPercentWei: maxConverterBonusPercent, // 0 or > 0

  //
  /**
   * Currencies select
   *
   * true - if selected fiat
   * true || false
   */
  isFiatOnly,
  /**
   * true - no need bank details
   *
   * true || false
   */
  isFiatConversionAutomaticallyApproved,

  // Campaign Dates
  campaignStartTime,
  campaignEndTime,

  // Tokens Lockup

  tokenDistributionDate: 1,
  maxDistributionDateShiftInDays: 180,
  numberOfVestingPortions: 6,
  numberOfDaysBetweenPortions: 1,
  bonusTokensVestingStartShiftInDaysFromDistributionDate: 180,

  // with bonus or without
  vestingAmount,

  // Advanced options - Participant details

  // Participation Limits
  minContributionETHWei: deployerProtocol.Utils.toWei(minContributionETHorUSD, 'ether'), // min === max or min < max
  maxContributionETHWei: deployerProtocol.Utils.toWei(maxContributionETHorUSD, 'ether'),
  /**
   * Ask for Identity Verification?
   * true - required contractor approve for each conversion
   *
   * true || false
   */
  isKYCRequired,
  // End campaign details step

  //Referral Reward
  maxReferralRewardPercentWei: maxReferralRewardPercent, // 0 or > 0

  // Only Participants can join the Referral program
  mustConvertToReferr: false,
  /**
   *
   * NOBONUS - maxReferralRewardPercentWei === 0
   * MANUAL - manual checked
   * vanilla types:
   * EQUAL -
   * EQUAL3X -
   * GROWING -
   */
  incentiveModel,
  // Limit the number of invites per referrer
  // number or inlimited
  referrerQuota: undefined,
  // Limit the number of users to start a referral chain
  // number or inlimited
  totalSupplyArcs: undefined,
};

const actions = {
  join: 'join',
  visit: 'visit',
  joinAndConvert: 'joinAndConvert',
};

const campaignUsers = {
  gmail: {
    cut: 50,
    percentCut: 0.5,
    action: actions.join
  },
  test4: {
    cut: 20,
    percentCut: 0.20,
    action: actions.join
  },
  renata: {
    cut: 20,
    percentCut: 0.2,
    action: actions.join
  },
};

describe(
  'CryptoReleaseInOneDayManually',
  () => {
    const storage = {
      campaign: undefined,
      campaignAddress: undefined,
      links: {
        deployer: undefined,
        gmail: undefined,
        test4: undefined,
        renata: undefined,
      },
    };

    before(function () {
      this.timeout(60000);

      return new Promise(async (resolve) => {
        const campaign = await createCampaign(campaignData, availableUsers.aydnep);
        const {
          campaignAddress, campaignPublicLinkKey, fSecret,
        } = campaign;
        storage.campaign = campaign;
        storage.campaignAddress = campaignAddress;
        storage.links.deployer = {link: campaignPublicLinkKey, fSecret: fSecret};
        resolve();
      })
    });

    checkCampaign(campaignData, storage, availableUsers.aydnep);

    it('should visit campaign as guest', async () => {
      const {web3: {address: aydnepAddress}} = availableUsers.aydnep;
      const {protocol} = availableUsers.guest;
      const {campaignAddress, links: {deployer}, campaign: {contractor}} = storage;

      const txHash = await protocol.AcquisitionCampaign
        .visit(campaignAddress, deployer.link, deployer.fSecret);
      const linkOwnerAddress = await protocol.PlasmaEvents.getVisitedFrom(
        campaignAddress, contractor, protocol.plasmaAddress,
      );
      expect(linkOwnerAddress).to.be.eq(aydnepAddress);
    }).timeout(60000);

    it('should create a join link for gmail user and aydnep as parent', async () => {
      const {web3: {address: aydnepAddress}} = availableUsers.aydnep;
      const {protocol, web3: {address}} = availableUsers.gmail;
      const {campaignAddress, links: {deployer}, campaign: {contractor}} = storage;

      await protocol.AcquisitionCampaign.visit(
        campaignAddress,
        deployer.link,
        deployer.fSecret,
      );

      const hash = await protocol.AcquisitionCampaign.join(
        campaignAddress,
        address, {
          cut: campaignUsers.gmail.cut,
          referralLink: deployer.link,
          fSecret: deployer.fSecret,
        });

      storage.links.gmail = hash;

      expect(ipfsRegex.test(hash.link)).to.be.eq(true);

      const linkOwnerAddress = await protocol.PlasmaEvents.getVisitedFrom(
        campaignAddress, contractor, protocol.plasmaAddress,
      );
      expect(linkOwnerAddress).to.be.eq(aydnepAddress);
    }).timeout(60000);


    /**
     * Separate test due to different user usage
     */
    it(`should decrease max referral reward to ${campaignUsers.gmail.cut}%`, async () => {
      const {protocol, web3: {address}} = availableUsers.test4;
      const {campaignAddress, links: {gmail}} = storage;

      await protocol.AcquisitionCampaign.visit(campaignAddress, gmail.link, gmail.fSecret);

      let maxReward = await protocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(
        campaignAddress,
        address, gmail.link, gmail.fSecret,
      );

      expect(maxReward).to.be.eq(
        rewardCalc(
          maxReferralRewardPercent,
          [
            campaignUsers.gmail.percentCut,
          ],
        ),
      );
    }).timeout(60000);

    it('should decrease available tokens amount to purchased amount by test4', async () => {
      const {protocol, web3: {address}} = availableUsers.test4;
      const {campaignAddress, links: {gmail}} = storage;

      const initialAmountOfTokens = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      const {totalTokens: amountOfTokensForPurchase} = await protocol.AcquisitionCampaign.getEstimatedTokenAmount(
        campaignAddress,
        campaignData.isFiatOnly,
        protocol.Utils.toWei((minContributionETHorUSD), 'ether')
      );

      const txHash = await protocol.AcquisitionCampaign.joinAndConvert(
        campaignAddress,
        protocol.Utils.toWei(minContributionETHorUSD, 'ether'),
        gmail.link,
        address,
        {fSecret: gmail.fSecret},
      );

      await protocol.Utils.getTransactionReceiptMined(txHash);

      const amountOfTokensAfterConvert = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      expect(amountOfTokensAfterConvert).to.be.eq(initialAmountOfTokens - amountOfTokensForPurchase);
    }).timeout(60000);

    it('should generate link for test4', async () => {
      const {protocol, web3: {address}} = availableUsers.test4;
      const {campaignAddress, links: {gmail}} = storage;

      const hash = await protocol.AcquisitionCampaign.join(
        campaignAddress,
        address, {
          cut: campaignUsers.test4.cut,
          referralLink: gmail.link,
          fSecret: gmail.fSecret
        },
      );
      const isJoined = await protocol.AcquisitionCampaign.isAddressJoined(campaignAddress, address);
      storage.links.test4 = hash;

      expect(ipfsRegex.test(hash.link)).to.be.eq(true);
      expect(isJoined).to.be.eq(true);
    }).timeout(600000);

    it('should check is test4 joined by gmail link', async () => {
      const {protocol} = availableUsers.test4;
      const {protocol: gmailProtocol} = availableUsers.gmail;
      const {campaignAddress, campaign: {contractor}} = storage;

      const joinedFrom = await protocol.PlasmaEvents.getJoinedFrom(
        campaignAddress,
        contractor,
        protocol.plasmaAddress,
      );

      expect(joinedFrom).to.eq(gmailProtocol.plasmaAddress)
    }).timeout(60000);

    it('should check maximum referral reward after visit test4 link', async () => {
      const {protocol, web3: {address}} = availableUsers.renata;
      const {campaignAddress, links: {test4}} = storage;

      await protocol.AcquisitionCampaign.visit(campaignAddress, test4.link, test4.fSecret);

      const maxReward = await protocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(
        campaignAddress, address, test4.link, test4.fSecret,
      );

      expect(maxReward).to.be.eq(
        Number.parseFloat(
          (
            rewardCalc(
              maxReferralRewardPercent,
              [
                campaignUsers.gmail.percentCut,
                campaignUsers.test4.percentCut
              ],
            )
          ).toFixed(2)
        )
      );
    }).timeout(60000);

    it('should joinOffchain as Renata', async () => {
      const {protocol, web3: {address}} = availableUsers.renata;
      const {campaignAddress, links: {test4}} = storage;

      const hash = await protocol.AcquisitionCampaign.join(campaignAddress, address, {
        cut: campaignUsers.renata.cut,
        referralLink: test4.link,
        fSecret: test4.fSecret,
      });

      storage.links.renata = hash;

      expect(ipfsRegex.test(hash.link)).to.be.eq(true);
    }).timeout(600000);

    it('should decrease available tokens amount to purchased amount by renata', async () => {
      const {protocol, web3: {address}} = availableUsers.renata;
      const {campaignAddress, links: {test4}} = storage;
      const contributionAmount = protocol.Utils.toWei((minContributionETHorUSD), 'ether');

      const initialAmountOfTokens = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      const {totalTokens: amountOfTokensForPurchase} = await protocol.AcquisitionCampaign.getEstimatedTokenAmount(
        campaignAddress,
        campaignData.isFiatOnly,
        contributionAmount
      );

      const txHash = await protocol.AcquisitionCampaign.joinAndConvert(
        campaignAddress,
        contributionAmount,
        test4.link,
        address,
        {fSecret: test4.fSecret},
      );

      await protocol.Utils.getTransactionReceiptMined(txHash);

      const amountOfTokensAfterConvert = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      expect(amountOfTokensAfterConvert).to.be.eq(initialAmountOfTokens - amountOfTokensForPurchase);
    }).timeout(60000);

    it('should buy some tokens from uport', async () => {
      const {protocol, web3: {address}} = availableUsers.uport;
      const {campaignAddress, links: {renata}} = storage;
      const contributionAmount = protocol.Utils.toWei((minContributionETHorUSD), 'ether');

      await protocol.AcquisitionCampaign.visit(campaignAddress, renata.link, renata.fSecret);

      const initialAmountOfTokens = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      const {totalTokens: amountOfTokensForPurchase} = await protocol.AcquisitionCampaign.getEstimatedTokenAmount(
        campaignAddress,
        campaignData.isFiatOnly,
        contributionAmount
      );

      const txHash = await protocol.AcquisitionCampaign.joinAndConvert(
        campaignAddress,
        contributionAmount,
        renata.link,
        address,
        {fSecret: renata.fSecret},
      );

      await protocol.Utils.getTransactionReceiptMined(txHash);

      const amountOfTokensAfterConvert = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      expect(prepareNumberForCompare(amountOfTokensAfterConvert)).to.be
        .eq(prepareNumberForCompare(initialAmountOfTokens - amountOfTokensForPurchase));
    }).timeout(60000);
    return;
    it('==> should print available amount of tokens after conversion', async () => {
      const {protocol, web3: {address}} = availableUsers.uport;
      const {campaignAddress} = storage;
      const availableAmountOfTokens = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );
      console.log('Available amount of tokens after conversion is: ' + availableAmountOfTokens);
    }).timeout(60000);
  },
);
