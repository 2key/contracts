import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import {campaignTypes} from "../../../../constants/smallConstants";

/**
 * We have two similar tests this one and referrerRewardStatsTest. Probably one can be removed
 * @param storage
 * @param userKey
 */

export default function checkReferrerRewardTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  it(`should check is referrers reward calculated correctly for ${userKey} conversions`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);
    const referrals = storage.getReferralsForUser(user);

    for (let i = 0; i < referrals.length; i += 1) {
      const refUser = referrals[i];
      const {protocol: {plasmaAddress}} = availableUsers[refUser.id];

      let refReward;

      switch (storage.campaignType) {
        case campaignTypes.acquisition:
          refReward = await protocol.AcquisitionCampaign
            .getReferrerPlasmaBalance(campaignAddress, plasmaAddress);
          break;
        case campaignTypes.donation:
          refReward = await protocol.DonationCampaign
            .getReferrerBalance(campaignAddress, plasmaAddress, address);
          break;
        case campaignTypes.cpc:
          refReward = await protocol.CPCCampaign.getReferrerBalanceInFloat(campaignAddress, plasmaAddress);
          break;
        default:
          throw new Error('Unknown campaign type');
      }

      expectEqualNumbers(
        refReward,
        refUser.referrerReward,
      );
    }
  }).timeout(60000);
}
