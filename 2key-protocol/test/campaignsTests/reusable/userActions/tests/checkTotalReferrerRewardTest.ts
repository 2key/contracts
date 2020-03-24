import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import donationOnly from "../checks/donationOnly";

export default function checkTotalReferrerRewardTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  donationOnly(storage.campaignType);

  it(`should check reserved amount for referrers`, async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const totalReferrersReward = await protocol.DonationCampaign.getReservedAmount2keyForRewards(campaignAddress);

    expectEqualNumbers(totalReferrersReward, storage.totalBounty);
  }).timeout(60000);
}
