import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import cpcOnly from "../checks/cpcOnly";

export default function mainChainBalancesSyncTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  cpcOnly(storage.campaignType);

  it(`should push and distribute balances for influencers to the mainchain from deployer`, async () => {
    const {protocol, web3:{address}} = availableUsers[userKey];
    const {campaignAddress, campaign} = storage;

    const numberOfInfluencers = await protocol.CPCCampaign.getNumberOfActiveInfluencers(campaignAddress);
    const resp = await protocol.CPCCampaign.getInfluencersAndBalances(
      campaignAddress, 0, numberOfInfluencers
    );

    await protocol.Utils.getTransactionReceiptMined(
      await protocol.CPCCampaign.pushBalancesForInfluencers(
        // @ts-ignore
        campaign.campaignAddressPublic,
        resp.influencers,
        resp.balances,
        address
      )
    );

    await protocol.Utils.getTransactionReceiptMined(
      await protocol.CPCCampaign.distributeRewardsBetweenInfluencers(
        // @ts-ignore
        campaign.campaignAddressPublic,
        resp.influencers,
        address,
      )
    );
    // TODO: add assertion
  }).timeout(60000);
}
