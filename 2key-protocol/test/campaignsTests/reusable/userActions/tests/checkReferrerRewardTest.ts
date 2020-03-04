import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import calculateReferralRewards from "../../../helpers/calculateReferralRewards";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";

export default function checkReferrerRewardTest(
  {
    storage,
    userKey,
    campaignData,
  }: functionParamsInterface,
) {
  /**
   *
   * Keep in mind that this function doesn't expect different converters for one referrer
   *      u2 -- u3 (with conversion)
   *    /
   * u1 - u4 -- u5 (with conversion)
   *
   * For fix this easiest way to store reward in users objects right after execution
   */
  it(`should check is referrers reward calculated correctly for ${userKey} conversions`, async () => {
    const {protocol, web3: {address: web3Address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);
    const referrals = storage.getReferralsForUser(user);
    const expectedRewards = calculateReferralRewards(campaignData.incentiveModel, referrals, user.referralsReward);
    const referralKeys = Object.keys(expectedRewards);

    for (let i = 0; i < referralKeys.length; i += 1) {
      const refKey = referralKeys[i];
      const expectReward = expectedRewards[refKey];
      const {protocol: {plasmaAddress}} = availableUsers[refKey];

      const refReward = storage.campaignType
        ? await protocol.AcquisitionCampaign
          .getReferrerPlasmaBalance(campaignAddress, plasmaAddress)
        : await protocol.DonationCampaign
          .getReferrerBalance(campaignAddress, plasmaAddress, web3Address);

      expectEqualNumbers(
        refReward,
        expectReward,
      );
    }
  }).timeout(60000);
}
