import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";

export default function checkCampaignSummaryTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  /**
   AcquisitionCampaign:
   {
     approvedConversions: 0
     approvedConverters: 1
     campaignRaisedByNow: 101.1534
     cancelledConversions: 0
     executedConversions: 1
     pendingConversions: 0
     pendingConverters: 0
     raisedFundsEthWei: 0.47
     raisedFundsFiatWei: 0
     rejectedConversions: 0
     rejectedConverters: 0
     tokensSold: 11228.0274
     totalBounty: 0
     uniqueConverters: 1
     }

   DonationCampaign:
   {
     approvedConversions: 0
     approvedConverters: 1
     campaignRaisedByNow: 81.7836
     cancelledConversions: 0
     executedConversions: 1
     pendingConversions: 0
     pendingConverters: 0
     raisedFundsEthWei: 0.38
     rejectedConversions: 0
     rejectedConverters: 0
     tokensSold: 81.7836
     totalBounty: 0
     uniqueConverters: 1
     }
   */
  it('should compare campaign summary with storage', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const summary = await protocol[campaignContract].getCampaignSummary(campaignAddress, address);

    expectEqualNumbers(
      summary.pendingConverters,
      storage.pendingUsers.length,
    );
    expectEqualNumbers(
      summary.approvedConverters,
      storage.approvedUsers.length,
    );
    expectEqualNumbers(
      summary.rejectedConverters,
      storage.rejectedUsers.length,
    );
    expectEqualNumbers(
      summary.pendingConversions,
      storage.pendingConversions.length,
    );
    expectEqualNumbers(
      summary.approvedConversions,
      storage.approvedConversions.length,
    );
    expectEqualNumbers(
      summary.cancelledConversions,
      storage.canceledConversions.length,
    );
    expectEqualNumbers(
      summary.rejectedConversions,
      storage.rejectedConversions.length,
    );
    expectEqualNumbers(
      summary.executedConversions,
      storage.executedConversions.length,
    );
    expectEqualNumbers(
      summary.tokensSold,
      storage.tokensSold,
    );
    expectEqualNumbers(
      summary.totalBounty,
      storage.totalBounty,
    );
  }).timeout(60000);

}
