import '../constants/polifils';
import availableUsers, {userIds} from "../constants/availableUsers";
import usersActions from "./reusable/userActions/usersActions";
import {campaignUserActions} from "./constants/constants";
import TestStorage from "../helperClasses/TestStorage";
import {campaignTypes, incentiveModels} from "../constants/smallConstants";
import {ICreateCampaign} from "../../src/donation/interfaces";
import createDonationCampaign from "./helpers/createDonationCampaign";
import checkDonationCampaign from "./reusable/checkDonationCampaign";
import {ICPCCampaign, ICreateCPC} from "../../src/cpc/interfaces";
import createCpcCampaign from "./helpers/createCpcCampaign";
import checkCpcCampaign from "./reusable/checkCpcCampaign";

const conversionSize = 1;

const  campaignData: ICreateCPC = {
  url: "https://2key.network",
  moderator: "",
  incentiveModel: incentiveModels.vanillaAverage,
  campaignStartTime : 0,
  campaignEndTime : 9884748832,
  bountyPerConversionWei: 3,
// @ts-ignore
  etherForRewards: 3,
};

describe(
  'exampleCpcTest',
  () => {
    const storage = new TestStorage(userIds.deployer, campaignTypes.cpc);

    before(function () {
      this.timeout(60000);
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
        cut: 10,
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
        cut: 10,
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
        cut: 10,
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
        cut: 10,
      }
    );
  },
);
