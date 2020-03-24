import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers, {userIds} from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import donationOnly from "../checks/donationOnly";

/**
 * We have two similar tests this one and checkReferrerRewardTest. Probably one can be removed
 * @param storage
 * @param userKey
 * @param campaignContract
 */
export default function referrerRewardStatsTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  donationOnly(storage.campaignType);

  it(`should check referrer stats for user ${userKey}`, async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    const signature = await protocol.PlasmaEvents.signReferrerToGetRewards();
    const {totalEarnings} = await protocol[campaignContract].getReferrerBalanceAndTotalEarningsAndNumberOfConversions(campaignAddress, signature);

    expectEqualNumbers(totalEarnings, user.referrerReward);
  }).timeout(60000);
}
