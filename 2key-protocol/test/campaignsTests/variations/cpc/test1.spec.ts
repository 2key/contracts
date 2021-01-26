import '../../../constants/polifils';
import {userIds} from "../../../constants/availableUsers";
import usersActions from "../../reusable/userActions/usersActions";
import {campaignUserActions} from "../../../constants/campaignUserActions";
import TestStorage from "../../../helperClasses/TestStorage";
import {campaignTypes, incentiveModels} from "../../../constants/smallConstants";
import createCpcCampaign from "../../../helpers/createCpcCampaign";
import checkCpcCampaign from "../../reusable/checkCpcCampaign";
import ICreateCPCTest from "../../../typings/ICreateCPCTest";

const  campaignData: ICreateCPCTest = {
  url: "https://2key.network",
  moderator: "",
  incentiveModel: incentiveModels.vanillaPowerLaw,
  campaignStartTime : 0,
  campaignEndTime : 9884748832,
  // will be reduced to fee amount, for now it is 2%, so it will be 3*0.98 = 2.94 per conversion
  bountyPerConversionUSD: 6,
  // Should fail on conversion stage
  // referrerQuota: 1,
  // etherForRewards: 3,
  targetClicks: 2,
};

describe(
  '2 clicks target, growing incentive model, end campaign when goal reached, 4 tokens pay per click',
  function() {
    const storage = new TestStorage(userIds.deployer, campaignTypes.cpc, true);
    this.timeout(10000);

    before(function () {
      return createCpcCampaign(campaignData, storage);
    });

    checkCpcCampaign(campaignData, storage, userIds.buyer);


    usersActions(
      {
        userKey: userIds.test,
        secondaryUserKey: storage.contractorKey,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.gmail,
        secondaryUserKey: userIds.test,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.join,
        ],
        campaignData,
        storage,
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
      }
    );

    usersActions(
      {
        userKey: userIds.buyer,
        secondaryUserKey: userIds.test4,
        actions: [
          campaignUserActions.executeConversion,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.renata,
        secondaryUserKey: userIds.gmail,
        actions: [
          campaignUserActions.visit,
          campaignUserActions.joinAndConvert,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.buyer,
        secondaryUserKey: userIds.renata,
        actions: [
          campaignUserActions.executeConversion,
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
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.renata,
        actions: [
          campaignUserActions.checkReferrersList,
          campaignUserActions.checkReferrerReward,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.buyer,
        actions: [
          campaignUserActions.lockContract
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.buyer,
        actions: [
          campaignUserActions.checkMainChainBalancesSync,
          campaignUserActions.checkCampaignSummary,
        ],
        campaignData,
        storage,
      }
    );

    usersActions(
      {
        userKey: userIds.test,
        actions: [
          campaignUserActions.checkModeratorEarnings,
        ],
        campaignData,
        storage,
      }
    );
  },
);
