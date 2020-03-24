import '../../../constants/polifils';
import getAcquisitionCampaignData from "../../../helpers/getAcquisitionCampaignData";
import {campaignTypes, incentiveModels, vestingSchemas} from "../../../constants/smallConstants";
import TestStorage from "../../../helperClasses/TestStorage";
import createAcquisitionCampaign from "../../../helpers/createAcquisitionCampaign";
import {userIds} from "../../../constants/availableUsers";
import checkAcquisitionCampaign from "../../reusable/checkAcquisitionCampaign";
import usersActions from "../../reusable/userActions/usersActions";
import {campaignUserActions} from "../../../constants/campaignUserActions";
import getTwoKeyEconomyAddress from "../../../helpers/getTwoKeyEconomyAddress";


const conversionSize = 5;

const campaignData = getAcquisitionCampaignData(
  {
    amount: 0,
    campaignInventory: 40000,
    maxConverterBonusPercent: 0,
    pricePerUnitInETHOrUSD: 0.095,
    maxReferralRewardPercent: 20,
    minContributionETHorUSD: 5,
    maxContributionETHorUSD: 1000000,
    campaignStartTime: 0,
    campaignEndTime: 9884748832,
    acquisitionCurrency: 'USD',
    twoKeyEconomy: getTwoKeyEconomyAddress(),
    isFiatOnly: true,
    isFiatConversionAutomaticallyApproved: true,
    vestingAmount: vestingSchemas.baseAndBonus,
    isKYCRequired: false,
    incentiveModel: incentiveModels.vanillaPowerLaw,
    tokenDistributionDate: 1,
    numberOfVestingPortions: 10,
    numberOfDaysBetweenPortions: 30,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: 180,
    maxDistributionDateShiftInDays: 180,
  }
);

describe(
  'FIAT, no bonus, no KYC, no bank, all tokens released in 10 equal parts every 30 days, starting 180 days after DD, growing incentive [Tokensale]',
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
        cut: 40,
      }
    );

    usersActions(
      {
        userKey: userIds.gmail2,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
        ],
        campaignData,
        storage,
        cut: 20,
      }
    );

    usersActions(
      {
        userKey: userIds.test4,
        secondaryUserKey: userIds.gmail2,
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
          campaignUserActions.checkReferrerReward,
        ],
        campaignData,
        storage,
      }
    );
  },
);
