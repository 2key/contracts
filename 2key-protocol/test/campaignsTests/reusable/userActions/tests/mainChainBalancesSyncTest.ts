import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import cpcOnly from "../checks/cpcOnly";
import {promisify} from "../../../../../src/utils/promisify";
import {expect} from "chai";

export default function mainChainBalancesSyncTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  cpcOnly(storage.campaignType);

  it(`should end campaign, reserve tokens, and rebalance rates as well`, async () => {
      //This is the test where maintainer ends campaign, does rates rebalancing, etc.
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress, campaign} = storage;

      let earnings = await protocol.CPCCampaign.getTotalReferrerRewardsAndTotalModeratorEarnings(campaignAddress);


      let txHash = await promisify(protocol.twoKeyBudgetCampaignsPaymentsHandler.methods.endCampaignReserveTokensAndRebalanceRates, [
          campaignAddress,
          protocol.Utils.toWei(earnings.totalAmountForReferrerRewards, 'ether').toString(),
          protocol.Utils.toWei(earnings.totalModeratorEarnings, 'ether').toString(),
          {from: address}
      ]);

      await new Promise(resolve => setTimeout(resolve, 2000));

      let info = await protocol.CPCCampaign.getCampaignPublicInfo(campaignAddress);

      expect(earnings.totalModeratorEarnings.toFixed(5)).to.be.equal((info.moderatorEarnings / info.rebalancingRatio).toFixed(5));
      expect(info.isLeftoverWithdrawn).to.be.equal(false);
  }).timeout(10000);

  it('should mark campaign as done and assign to active influencers', async() => {
      const {protocol, web3:{address}} = availableUsers[userKey];
      const {campaignAddress, campaign} = storage;

      let numberOfActiveInfluencers = await protocol.CPCCampaign.getNumberOfActiveInfluencers(campaignAddress);
      let campaignInstance = await protocol.CPCCampaign._getPlasmaCampaignInstance(campaignAddress);
      let influencers = await promisify(campaignInstance.methods.getActiveInfluencers,[0,numberOfActiveInfluencers]);

      let referrerPendingCampaigns = await promisify(protocol.twoKeyPlasmaBudgetCampaignsPaymentsHandler.methods.getCampaignsReferrerHasPendingBalances,[influencers[0]]);

        let txHash = await promisify(protocol.twoKeyPlasmaBudgetCampaignsPaymentsHandler.methods.markCampaignAsDoneAndAssignToActiveInfluencers,[
          campaignAddress,
          0,
          numberOfActiveInfluencers,
          {
              from: protocol.plasmaAddress,
              gas: 7800000
          }
        ]);

      await new Promise(resolve => setTimeout(resolve, 2000));

      let referrerPendingCampaignsAfter = await promisify(protocol.twoKeyPlasmaBudgetCampaignsPaymentsHandler.methods.getCampaignsReferrerHasPendingBalances,[influencers[0]]);
      expect(referrerPendingCampaigns.length).to.be.equal(referrerPendingCampaignsAfter.length - 1);
      expect(referrerPendingCampaignsAfter[referrerPendingCampaignsAfter.length-1].toLowerCase()).to.be.equal(campaignAddress.toLowerCase());

  }).timeout(10000);
}
