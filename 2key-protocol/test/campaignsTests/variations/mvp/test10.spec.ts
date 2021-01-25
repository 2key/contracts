import '../../../constants/polifils';
import {campaignTypes, incentiveModels} from "../../../constants/smallConstants";
import TestStorage from "../../../helperClasses/TestStorage";
import {userIds} from "../../../constants/availableUsers";
import usersActions from "../../reusable/userActions/usersActions";
import {campaignUserActions} from "../../../constants/campaignUserActions";
import {ICreateCampaign} from "../../../../src/donation/interfaces";
import createDonationCampaign from "../../../helpers/createDonationCampaign";
import checkDonationCampaign from "../../reusable/checkDonationCampaign";

const conversionSize = 1;

const campaignData: ICreateCampaign = {
  moderator: undefined,
  invoiceToken: {
    tokenName: 'NikolaToken',
    tokenSymbol: 'NTKN',
  },
  maxReferralRewardPercent: 20,
  campaignStartTime: 0,
  campaignEndTime: 9884748832,
  minDonationAmount: 1,
  maxDonationAmount: 10,
  campaignGoal: 10000,
  referrerQuota: 5,
  isKYCRequired: false,
  shouldConvertToRefer: false,
  acceptsFiat: false,
  incentiveModel: incentiveModels.vanillaAverage,
  currency: 'ETH',
  endCampaignOnceGoalReached: false,
  expiryConversionInHours: 0,
};

describe(
  'ETH, no KYC, equal incentive  [Donation]',
  () => {
    const storage = new TestStorage(userIds.aydnep, campaignTypes.donation, campaignData.isKYCRequired);

    before(function () {
      this.timeout(60000);
      return createDonationCampaign(campaignData, storage);
    });

    checkDonationCampaign(campaignData, storage);

    usersActions(
      {
        userKey: userIds.guest,
        secondaryUserKey: storage.contractorKey,
        actions: [campaignUserActions.visit],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.gmail,
        secondaryUserKey: storage.contractorKey,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
        ],
        campaignData,
        storage,
        cut: 50,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.joinAndConvert,
          campaignUserActions.checkConverterSpent,
        ],
        campaignData,
        storage,
        contribution: conversionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.renata,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.joinAndConvert,
          campaignUserActions.checkConverterSpent,
        ],
        campaignData,
        storage,
        contribution: conversionSize,
      }
    );


    usersActions(
      {
        userKey: storage.contractorKey,
        secondaryUserKey: userIds.test4,
        actions: [
          campaignUserActions.checkERC20Balance,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        actions: [
          campaignUserActions.checkReferrersList,
          campaignUserActions.checkReferrerReward,
          campaignUserActions.checkAvailableDonation,
          campaignUserActions.checkStatistic,
          campaignUserActions.checkContractorBalanceAndProceeds,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.gmail,
        actions: [
          campaignUserActions.checkReferrerRewardStats,
          campaignUserActions.moderatorAndReferrerWithdraw,
        ],
        campaignData,
        storage,
      }
    );
  },
);
