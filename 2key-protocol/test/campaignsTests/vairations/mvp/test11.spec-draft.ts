import '../../../constants/polifils';
import getAcquisitionCampaignData from "../../helpers/getAcquisitionCampaignData";
import {campaignTypes, incentiveModels, vestingSchemas} from "../../../constants/smallConstants";
import TestStorage from "../../../helperClasses/TestStorage";
import createAcquisitionCampaign from "../../helpers/createAcquisitionCampaign";
import checkAcquisitionCampaign from "../../reusable/checkAcquisitionCampaign";
import usersActions from "../../reusable/userActions/usersActions";
import {campaignUserActions} from "../../constants/constants";
import getTwoKeyEconomyAddress from "../../helpers/getTwoKeyEconomyAddress";
import registerRandomUser, {getUniqueId} from "../../helpers/registerRandomUser";
import availableUsers, {userIds} from "../../../constants/availableUsers";

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
    vestingAmount: vestingSchemas.baseAndBonus,
    isKYCRequired: false,
    incentiveModel: incentiveModels.manual,
    tokenDistributionDate: 1,
    numberOfVestingPortions: 5,
    numberOfDaysBetweenPortions: 7,
    bonusTokensVestingStartShiftInDaysFromDistributionDate: 0,
    maxDistributionDateShiftInDays: 0,
  }
);


describe(
  'ETH, no bonus, no KYC, all tokens released in 5 equal parts every 7 days [Tokensale with new users]',
  () => {
    const randomUserIds = {
      contractor: getUniqueId(),
      referrer: getUniqueId(),
      converter: getUniqueId(),
    };

    const storage = new TestStorage(randomUserIds.contractor, campaignTypes.acquisition, campaignData.isKYCRequired);

    storage.addUser(randomUserIds.contractor);
    storage.addUser(randomUserIds.referrer);
    storage.addUser(randomUserIds.converter);

    before(async function () {
      this.timeout(600000);

      // @ts-ignore
      availableUsers[randomUserIds.contractor] = await registerRandomUser(randomUserIds.contractor, campaignData.campaignInventory* 2, conversionSize * 2);
      // @ts-ignore
      availableUsers[randomUserIds.referrer] = await registerRandomUser(randomUserIds.referrer, undefined, conversionSize * 2);
      // @ts-ignore
      availableUsers[randomUserIds.converter] = await registerRandomUser(randomUserIds.converter, undefined, conversionSize * 2);

      await createAcquisitionCampaign(campaignData, storage);
    });

    checkAcquisitionCampaign(campaignData, storage);
    usersActions(
      {
        userKey: randomUserIds.referrer,
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
        userKey: randomUserIds.converter,
        secondaryUserKey: randomUserIds.referrer,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.joinAndConvert,
          campaignUserActions.checkConversionPurchaseInfo,
        ],
        campaignData,
        storage,
        contribution: conversionSize,
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
        userKey: randomUserIds.referrer,
        actions: [
          campaignUserActions.moderatorAndReferrerWithdraw,
          campaignUserActions.checkModeratorEarnings,
          campaignUserActions.checkERC20Balance,
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
  },
);
