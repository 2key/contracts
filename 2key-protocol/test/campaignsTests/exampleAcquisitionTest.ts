import '../constants/polifils';
import availableUsers, {userIds} from "../constants/availableUsers";
import singletons from "../../src/contracts/singletons";
import createAcquisitionCampaign from "./helpers/createAcquisitionCampaign";
import checkAcquisitionCampaign from "./reusable/checkAcquisitionCampaign";
import usersActions from "./reusable/usersActions";
import {campaignUserActions} from "./constants/constants";
import TestStorage from "../helperClasses/TestStorage";
import {availableStorageUserFields} from "../constants/storageConstants";
import {campaignTypes, incentiveModels, vestingSchemas} from "../constants/smallConstants";
import getAcquisitionCampaignData from "./helpers/getAcquisitionCampaignData";

const {env} = process;
const networkId = parseInt(env.MAIN_NET_ID, 10);
const contributionSize = 5;

const campaignData = getAcquisitionCampaignData(
  {
    amount: 0,
    campaignInventory: 1234000,
    maxConverterBonusPercent: 15,
    pricePerUnitInETHOrUSD: 0.095,
    maxReferralRewardPercent: 20,
    minContributionETHorUSD: contributionSize,
    maxContributionETHorUSD: 1000000,
    campaignStartTime: 0,
    campaignEndTime: 9884748832,
    acquisitionCurrency: 'USD',
    twoKeyEconomy: singletons.TwoKeyEconomy.networks[networkId].address,
    isFiatOnly: false,
    isFiatConversionAutomaticallyApproved: true,
    vestingAmount: vestingSchemas.bonus,
    isKYCRequired: true,
    incentiveModel: incentiveModels.manual,
    tokenDistributionDate: 1,
    numberOfVestingPortions: 6,
    numberOfDaysBetweenPortions: 1,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: 10,
    maxDistributionDateShiftInDays: 10,
  }
);

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
  'exampleAcquisitionTest.ts',
  () => {
    const storage = new TestStorage(userIds.aydnep, campaignTypes.acquisition, campaignData.isKYCRequired);

    before(function () {
      this.timeout(60000);
      return createAcquisitionCampaign(campaignData, storage);
    });

    checkAcquisitionCampaign(campaignData, storage);

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
        cut: campaignUsers.gmail.cut,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.checkManualCutsChain,
          campaignUserActions.join,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        cut: campaignUsers.test4.cut,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.renata,
        secondaryUserKey: userIds.test4,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.checkManualCutsChain,
          campaignUserActions.join,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        cut: campaignUsers.renata.cut,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.uport,
        secondaryUserKey: userIds.renata,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.checkManualCutsChain,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.gmail2,
        secondaryUserKey: userIds.renata,
        actions: [
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.buyer,
        secondaryUserKey: userIds.renata,
        actions: [
          campaignUserActions.joinAndConvert,
          campaignUserActions.cancelConvert,
        ],
        campaignData,
        storage,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.test,
        secondaryUserKey: userIds.renata,
        actions: [
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
        contribution: contributionSize,
      }
    );

    usersActions(
      {
        userKey: storage.contractorKey,
        secondaryUserKey: userIds.test4,
        actions: [
          campaignUserActions.checkPendingConverters,
          campaignUserActions.approveConverter,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: storage.contractorKey,
        secondaryUserKey: userIds.gmail2,
        actions: [
          campaignUserActions.approveConverter,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: storage.contractorKey,
        secondaryUserKey: userIds.test,
        actions: [
          campaignUserActions.rejectConverter,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.test,
        actions: [
          campaignUserActions.checkRestrictedConvert,
          campaignUserActions.checkStatistic,
        ],
        contribution: contributionSize,
        campaignData,
        storage,
      }
    );
    usersActions(
      {
        userKey: userIds.test4,
        actions: [
          campaignUserActions.executeConversion,
          campaignUserActions.checkConversionPurchaseInfo,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: storage.contractorKey,
        actions: [
          campaignUserActions.hedgingEth,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        actions: [
          campaignUserActions.checkCampaignSummary,
          campaignUserActions.checkModeratorEarnings,
          campaignUserActions.withdrawTokens,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: storage.contractorKey,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.checkWithdrawableBalance,
        ],
        campaignData,
        storage,
      }
    );
    usersActions(
      {
        userKey: storage.contractorKey,
        actions: [
          campaignUserActions.contractorWithdraw,
        ],
        campaignData,
        storage,
      }
    );
    usersActions(
      {
        userKey: userIds.gmail,
        actions: [
          campaignUserActions.checkStatistic,
        ],
        campaignData,
        storage,
      }
    );
    usersActions(
      {
        userKey: userIds.renata,
        actions: [
          campaignUserActions.moderatorAndReferrerWithdraw,
          campaignUserActions.checkTotalEarnings,
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
          campaignUserActions.checkConverterMetric,
        ],
        campaignData,
        storage,
      }
    );
    usersActions(
      {
        userKey: userIds.gmail2,
        actions: [
          campaignUserActions.createOffline,
        ],
        campaignData,
        storage,
        contribution: 50,
      }
    );
    usersActions(
      {
        userKey: storage.contractorKey,
        actions: [
          campaignUserActions.contractorExecuteConversion,
        ],
        campaignData,
        storage,
      }
    );
  },
);
