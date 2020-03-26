import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import cpcOnly from "../checks/cpcOnly";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import getTwoKeyEconomyAddress from "../../../../helpers/getTwoKeyEconomyAddress";

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
    // @ts-ignore
    const campaignPublicAddress = campaign.campaignAddressPublic;

    const balanceBefore =  await protocol.ERC20.getERC20Balance(getTwoKeyEconomyAddress(), campaignPublicAddress);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol.CPCCampaign.pushBalancesForInfluencers(
        campaignPublicAddress,
        resp.influencers,
        resp.balances.map(balance => protocol.Utils.toWei(balance,'ether')),
        address
      )
    );

    await protocol.Utils.getTransactionReceiptMined(
      await protocol.CPCCampaign.distributeRewardsBetweenInfluencers(
        campaignPublicAddress,
        resp.influencers,
        address,
      )
    );

    const balanceAfter =  await protocol.ERC20.getERC20Balance(getTwoKeyEconomyAddress(), campaignPublicAddress);

      expectEqualNumbers(
          balanceBefore,
          balanceAfter + resp.balances.reduce((accum, num) => {accum += num; return accum;}, 0)
      );

  }).timeout(60000);
}
