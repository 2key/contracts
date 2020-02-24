import {expect} from "chai";

import '../constants/polifils';
import availableUsers, {userIds} from "../constants/availableUsers";
import singletons from "../../src/contracts/singletons";
import createCampaign from "./helpers/createCampaign";
import checkCampaign from "./reusable/checkCampaign.spec";
import usersActions from "./reusable/usersActions.spec";
import {campaignUserActions} from "./constants/constants";

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
  // should be date
  tokenDistributionDate: 1,
  maxDistributionDateShiftInDays: 180,
  // total amount divider, how payments will be
  numberOfVestingPortions: 6,
  // Interval between payments in days
  numberOfDaysBetweenPortions: 1,
  // only BONUS, when bonus payments payouts start in days
  bonusTokensVestingStartShiftInDaysFromDistributionDate: 180,

  // with bonus or without, BASE_AND_BONUS or BONUS
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

const campaignUsers = {
  gmail: {
    cut: 50,
    percentCut: 0.5,
  },
  test4: {
    cut: 20,
    percentCut: 0.20,
  },
  renata: {
    cut: 20,
    percentCut: 0.2,
  },
};

describe(
  'CryptoReleaseInOneDayManually',
  () => {
    const storage = {
      campaign: undefined,
      campaignAddress: undefined,
      links: {
        [userIds.aydnep]: undefined,
        [userIds.gmail]: undefined,
        [userIds.test4]: undefined,
        [userIds.renata]: undefined,
      },
      envData: {
        pendingConverters: [],
        approvedConverters: [],
        rejectedConverters: [],
      },
      counters: {
        approvedConversions: 0,
        approvedConverters: 0,
        campaignRaisedByNow: 0,
        cancelledConversions: 0,
        executedConversions: 0,
        pendingConversions: 0,
        pendingConverters: 0,
        raisedFundsEthWei: 0,
        raisedFundsFiatWei: 0,
        rejectedConversions: 0,
        rejectedConverters: 0,
        tokensSold: 0,
        totalBounty: 0,
        uniqueConverters: 0,
      }
    };

    before(function () {
      this.timeout(60000);

      return new Promise(async (resolve) => {
        const campaign = await createCampaign(campaignData, availableUsers[userIds.aydnep]);
        const {
          campaignAddress, campaignPublicLinkKey, fSecret,
        } = campaign;
        storage.campaign = campaign;
        storage.campaignAddress = campaignAddress;
        storage.links[userIds.aydnep] = {link: campaignPublicLinkKey, fSecret: fSecret};
        resolve();
      })
    });

    checkCampaign(campaignData, storage, userIds.aydnep);

    usersActions(
      {
        userKey: userIds.guest,
        refererKey: userIds.aydnep,
        actions: [campaignUserActions.visit],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.gmail,
        refererKey: userIds.aydnep,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
        ],
        campaignData,
        storage,
        cut: campaignUsers.gmail.cut,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        refererKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        cut: campaignUsers.test4.cut,
        contribution: minContributionETHorUSD,
        cutChain: [
          campaignUsers.gmail.percentCut,
        ],
      }
    );

    usersActions(
      {
        userKey: userIds.renata,
        refererKey: userIds.test4,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        cut: campaignUsers.renata.cut,
        contribution: minContributionETHorUSD,
        cutChain: [
          campaignUsers.gmail.percentCut,
          campaignUsers.test4.percentCut,
        ],
      }
    );

    usersActions(
      {
        userKey: userIds.uport,
        refererKey: userIds.renata,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        contribution: minContributionETHorUSD,
        cutChain: [
          campaignUsers.gmail.percentCut,
          campaignUsers.test4.percentCut,
          campaignUsers.renata.percentCut,
        ],
      }
    );

    usersActions(
      {
        userKey: userIds.gmail2,
        refererKey: userIds.renata,
        actions: [
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        contribution: minContributionETHorUSD,
        cutChain: [
          campaignUsers.gmail.percentCut,
          campaignUsers.test4.percentCut,
          campaignUsers.renata.percentCut,
        ],
      }
    );

    usersActions(
      {
        userKey: userIds.buyer,
        refererKey: userIds.renata,
        actions: [
          campaignUserActions.joinAndConvert,
          campaignUserActions.cancelConvert,
        ],
        campaignData,
        storage,
        contribution: minContributionETHorUSD,
      }
    );

    usersActions(
      {
        userKey: userIds.test,
        refererKey: userIds.renata,
        actions: [
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        contribution: minContributionETHorUSD,
      }
    );

    if (campaignData.isKYCRequired) {
      it('should check pendinf converters', async () => {
        const {protocol, web3: {address}} = availableUsers[userIds.aydnep];
        const {campaignAddress} = storage;

        const addresses = await protocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, address);

        expect(addresses).to.deep.equal(storage.envData.pendingConverters);
      }).timeout(60000);

      it('should approve converter', async () => {
        const {protocol, web3: {address}} = availableUsers[userIds.aydnep];
        const {address: test4Address, web3: {address: test4Web3Address}} = availableUsers[userIds.test4];
        const {address: gmail2Address, web3: {address: gmail2Web3Address}} = availableUsers[userIds.gmail2];
        const {campaignAddress} = storage;

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.approveConverter(campaignAddress, test4Address, address),
        );
        storage.envData.pendingConverters = storage.envData.pendingConverters.filter(
          (val) => (val !== test4Web3Address)
        );
        storage.envData.approvedConverters.push(test4Web3Address);

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.approveConverter(campaignAddress, gmail2Address, address)
        );

        storage.envData.pendingConverters = storage.envData.pendingConverters.filter(
          (val) => (val !== gmail2Web3Address)
        );
        storage.envData.approvedConverters.push(gmail2Web3Address);

        const approved = await protocol.AcquisitionCampaign.getApprovedConverters(campaignAddress, address);
        const pending = await protocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, address);

        expect(approved)
          .to.have.deep.members(storage.envData.approvedConverters)
          .to.not.have.members(storage.envData.pendingConverters);
        expect(pending)
          .to.have.deep.members(storage.envData.pendingConverters)
          .to.not.have.members(storage.envData.approvedConverters);
      }).timeout(60000);

      // TODO: maybe assert for conversion array should be empty
      // TODO: recheck for error on next Convert
      it('should reject converter', async () => {
        const {protocol, web3: {address}} = availableUsers[userIds.aydnep];
        const {address: testAddress, web3: {address: testWeb3Address}} = availableUsers[userIds.test];
        const {campaignAddress} = storage;

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.rejectConverter(campaignAddress, testAddress, address)
        );

        storage.envData.pendingConverters = storage.envData.pendingConverters.filter(
          (val) => (val !== testWeb3Address)
        );
        storage.envData.rejectedConverters.push(testWeb3Address);

        const rejected = await protocol.AcquisitionCampaign.getAllRejectedConverters(campaignAddress, address);
        const pending = await protocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, address);

        expect(rejected)
          .to.have.deep.members(storage.envData.rejectedConverters)
          .to.not.have.members(storage.envData.pendingConverters);
        expect(pending)
          .to.have.deep.members(storage.envData.pendingConverters)
          .to.not.have.members(storage.envData.rejectedConverters);
      }).timeout(60000);
    }
  },
);
