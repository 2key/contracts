import '../../../../constants/polifils';
import getAcquisitionCampaignData from "../../../helpers/getAcquisitionCampaignData";
import {campaignTypes, incentiveModels, vestingSchemas} from "../../../../constants/smallConstants";
import TestStorage from "../../../../helperClasses/TestStorage";
import createAcquisitionCampaign from "../../../helpers/createAcquisitionCampaign";
import {userIds} from "../../../../constants/availableUsers";
import checkAcquisitionCampaign from "../../../reusable/checkAcquisitionCampaign";
import usersActions from "../../../reusable/userActions/usersActions";
import {campaignUserActions} from "../../../constants/constants";
import getTwoKeyEconomyAddress from "../../../helpers/getTwoKeyEconomyAddress";

const conversionSize = 5;

const campaignData = getAcquisitionCampaignData(
  {
    amount: 0,
    campaignInventory: 1234000,
    maxConverterBonusPercent: 0,
    pricePerUnitInETHOrUSD: 0.095,
    maxReferralRewardPercent: 20,
    minContributionETHorUSD: 5,
    maxContributionETHorUSD: 1000000,
    campaignStartTime: 0,
    campaignEndTime: 9884748832,
    acquisitionCurrency: 'ETH',
    twoKeyEconomy: getTwoKeyEconomyAddress(),
    isFiatOnly: false,
    isFiatConversionAutomaticallyApproved: true,
    vestingAmount: vestingSchemas.bonus,
    isKYCRequired: false,
    incentiveModel: incentiveModels.manual,
    tokenDistributionDate: 1,
    numberOfVestingPortions: 7,
    numberOfDaysBetweenPortions: 15,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: 80,
    maxDistributionDateShiftInDays: 80,
  }
);

describe(
  'ETH - Modified Token Lockup: Bonus',
  () => {
    const storage = new TestStorage(userIds.aydnep, campaignTypes.acquisition, campaignData.isKYCRequired);

    before(function () {
      this.timeout(60000);
      return createAcquisitionCampaign(campaignData, storage);
    });

    checkAcquisitionCampaign(campaignData, storage);

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
        ],
        campaignData,
        storage,
        contribution: conversionSize,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        actions: [
          campaignUserActions.checkConversionPurchaseInfo,
        ],
        campaignData,
        storage,
      }
    );
  },
);
