import '../../../constants/polifils';
import getAcquisitionCampaignData from "../../helpers/getAcquisitionCampaignData";
import singletons from "../../../../src/contracts/singletons";
import {campaignTypes, incentiveModels, vestingSchemas} from "../../../constants/smallConstants";
import TestStorage from "../../../helperClasses/TestStorage";
import createAcquisitionCampaign from "../../helpers/createAcquisitionCampaign";
import {userIds} from "../../../constants/availableUsers";
import checkAcquisitionCampaign from "../../reusable/checkAcquisitionCampaign";
import usersActions from "../../reusable/userActions/usersActions";
import {campaignUserActions} from "../../constants/constants";

const conversionSize = 5;
const networkId = parseInt(process.env.MAIN_NET_ID, 10);

const campaignData = getAcquisitionCampaignData(
  {
    amount: 0,
    campaignInventory: 1234000,
    maxConverterBonusPercent: 100,
    pricePerUnitInETHOrUSD: 0.095,
    maxReferralRewardPercent: 20,
    minContributionETHorUSD: 5,
    maxContributionETHorUSD: 1000000,
    campaignStartTime: 0,
    campaignEndTime: 9884748832,
    acquisitionCurrency: 'USD',
    twoKeyEconomy: singletons.TwoKeyEconomy.networks[networkId].address,
    isFiatOnly: true,
    isFiatConversionAutomaticallyApproved: true,
    vestingAmount: vestingSchemas.baseAndBonus,
    isKYCRequired: false,
    incentiveModel: incentiveModels.manual,
    tokenDistributionDate: 1,
    numberOfVestingPortions: 1,
    numberOfDaysBetweenPortions: 0,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: 0,
    maxDistributionDateShiftInDays: 0,
  }
);

describe(
  'with Campaign Bonus & no Token Lockup (FIAT)',
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
