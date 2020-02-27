import '../../constants/polifils';
import getCampaignData from "../helpers/getCampaignData";
import singletons from "../../../src/contracts/singletons";
import {incentiveModels, vestingSchemas} from "../../constants/smallConstants";
import TestStorage from "../../helperClasses/TestStorage";
import createCampaign from "../helpers/createCampaign";
import {userIds} from "../../constants/availableUsers";
import checkCampaign from "../reusable/checkCampaign";
import usersActions from "../reusable/usersActions";
import {campaignUserActions} from "../constants/constants";


const conversionSize = 5;
const networkId = parseInt(process.env.MAIN_NET_ID, 10);

const campaignData = getCampaignData(
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
    acquisitionCurrency: 'ETH',
    twoKeyEconomy: singletons.TwoKeyEconomy.networks[networkId].address,
    isFiatOnly: false,
    isFiatConversionAutomaticallyApproved: true,
    vestingAmount: vestingSchemas.baseAndBonus,
    isKYCRequired: true,
    incentiveModel: incentiveModels.manual,
    tokenDistributionDate: 1,
    numberOfVestingPortions: 10,
    numberOfDaysBetweenPortions: 30,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: 90,
    maxDistributionDateShiftInDays: 0,
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
  'ETH, with bonus, with KYC, all tokens released in 10 equal parts every 30 days, starting 90 days after DD, manual incentive [Tokensale]',
  () => {
    const storage = new TestStorage(userIds.aydnep);

    before(function () {
      this.timeout(60000);
      return createCampaign(campaignData, storage);
    });

    checkCampaign(campaignData, storage);

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
          campaignUserActions.joinAndConvert,
        ],
        cutChain: [
          campaignUsers.gmail.percentCut,
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
          campaignUserActions.cancelConvert,
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
                campaignUserActions.checkPendingConverters,
                campaignUserActions.approveConverter,
            ],
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
  },
);
