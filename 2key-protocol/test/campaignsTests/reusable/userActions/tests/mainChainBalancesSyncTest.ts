import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import cpcOnly from "../checks/cpcOnly";
import getTwoKeyEconomyAddress from "../../../helpers/getTwoKeyEconomyAddress";

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
    const balanceBefore =  await protocol.ERC20.getERC20Balance(getTwoKeyEconomyAddress(), address);

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

    const balanceAfter =  await protocol.ERC20.getERC20Balance(getTwoKeyEconomyAddress(), address);

console.log({balanceBefore, balanceAfter,
  diff: balanceBefore - balanceAfter,
  sum: resp.balances.reduce((accum, num) => {accum += num; return accum;}, 0)
});
    // TODO: add assertion sum(resp.balances) === balances diff
    // use protocol.ERC20.getERC20Balance(invoiceToken, secondaryUserAddress)
  }).timeout(60000);
}
