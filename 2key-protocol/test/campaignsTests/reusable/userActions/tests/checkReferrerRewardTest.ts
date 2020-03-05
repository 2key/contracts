import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";

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
    const {protocol, web3: {address: web3Address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);
    const referrals = storage.getReferralsForUser(user);

    for (let i = 0; i < referrals.length; i += 1) {
      const refUser = referrals[i];
      const {protocol: {plasmaAddress}} = availableUsers[refUser.id];

      const refReward = storage.campaignType
        ? await protocol.AcquisitionCampaign
          .getReferrerPlasmaBalance(campaignAddress, plasmaAddress)
        : await protocol.DonationCampaign
          .getReferrerBalance(campaignAddress, plasmaAddress, web3Address);

      expectEqualNumbers(
        refReward,
        refUser.referrerReward,
      );
    }
  }).timeout(60000);
}
