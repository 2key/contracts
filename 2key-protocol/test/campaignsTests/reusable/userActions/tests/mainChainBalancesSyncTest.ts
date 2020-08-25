import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import cpcOnly from "../checks/cpcOnly";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import getTwoKeyEconomyAddress from "../../../../helpers/getTwoKeyEconomyAddress";
import {promisify} from "../../../../../src/utils/promisify";

export default function mainChainBalancesSyncTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  cpcOnly(storage.campaignType);

  it(`should end campaign, reserve tokens, and rebalance rates as well`, async () => {
      //This is the test where maintainer ends campaign, does rates rebalancing, etc.
      const {protocol, web3:{address}} = availableUsers[userKey];
      const {campaignAddress, campaign} = storage;
      let budgetOnContract = await protocol.CPCCampaign.getInitialParamsForCampaign(campaignAddress);
      let earnings = await protocol.CPCCampaign.getTotalReferrerRewardsAndTotalModeratorEarnings(campaignAddress);
      await promisify(protocol.twoKeyBudgetCampaignsPaymentsHandler.endCampaignReserveTokensAndRebalanceRates,[
        campaignAddress,
        protocol.Utils.toWei(earnings.totalAmountForReferrerRewards,'ether').toString(),
        protocol.Utils.toWei(earnings.totalModeratorEarnings,'ether').toString(),
          {from: address}
      ]);
  }).timeout(60000);
}
