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

  it('should mark campaign as done and assign to active influencers', async() => {
      const {protocol, web3:{address}} = availableUsers[userKey];
      const {campaignAddress, campaign} = storage;

      let numberOfActiveInfluencers = await protocol.CPCCampaign.getNumberOfActiveInfluencers(campaignAddress);
      console.log(numberOfActiveInfluencers);
      let contractorAddress = await protocol.CPCCampaign.getContractorAddresses(campaignAddress);
      console.log(contractorAddress);
      let campaignInstance = await protocol.CPCCampaign._getPlasmaCampaignInstance(campaignAddress);
      let influencers = await promisify(campaignInstance.getActiveInfluencers,[0,numberOfActiveInfluencers]);
      let conversion = await protocol.CPCCampaign.getConversion(campaignAddress,0);
      let referrers = await protocol.CPCCampaign.getReferrers(campaignAddress, conversion.converterPlasma);
      console.log(referrers);
      console.log(conversion);
      console.log('influencers',influencers);
      console.log('maintainer',protocol.plasmaAddress);

      await promisify(protocol.twoKeyPlasmaBudgetCampaignsPaymentsHandler.markCampaignAsDoneAndAssignToActiveInfluencers,[
          campaignAddress,
          0,
          numberOfActiveInfluencers,
          {from: protocol.plasmaAddress}
      ]);

  }).timeout(60000);
}
