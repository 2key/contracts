import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import {campaignTypes, feePercent} from "../../../../constants/smallConstants";

export default function checkCampaignSummaryTest(
  {
    storage,
    userKey,
    campaignContract,
    campaignData,
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
     executedConversionsTotal: 11228.0274
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
     executedConversionsTotal: 81.7836
     totalBounty: 0
     uniqueConverters: 1
     }

   CPC

   {
      pendingConverters: 0,
      approvedConverters: 1,
      rejectedConverters: 0,
      pendingConversions: 0,
      rejectedConversions: 0,
      executedConversions: 1,
      totalBounty: 2.94
   }
   */
  it('should compare campaign summary with storage', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const summary = await protocol[campaignContract].getCampaignSummary(campaignAddress, address);
    const bounty = await protocol[campaignContract].getTotalBountyAndBountyPerConversion(campaignAddress);
    const bountyPerConversion = bounty.bountyPerConversion;

    expectEqualNumbers(
      summary.pendingConverters,
      storage.pendingUsers.length,
      'pendingConverters',
    );
    expectEqualNumbers(
      summary.approvedConverters,
      storage.approvedUsers.length,
      'approvedConverters'
    );
    expectEqualNumbers(
      summary.rejectedConverters,
      storage.rejectedUsers.length,
      'rejectedConverters',
    );
    expectEqualNumbers(
      summary.pendingConversions,
      storage.pendingConversions.length,
      'pendingConversions',
    );
    expectEqualNumbers(
      summary.rejectedConversions,
      storage.rejectedConversions.length,
      'rejectedConversions',
    );
    expectEqualNumbers(
      summary.executedConversions,
      storage.executedConversions.length,
      'executedConversions',
    );
    expectEqualNumbers(
      summary.totalBounty*0.98,
      storage.totalBounty,
      'totalBounty',
    );

    if (storage.campaignType === campaignTypes.cpc) {
      expectEqualNumbers(
        summary.totalBounty,
        summary.executedConversions * bountyPerConversion,
        'totalBounty'
      );
    } else {
      expectEqualNumbers(
        summary.approvedConversions,
        storage.approvedConversions.length,
        'approvedConversions',
      );
      expectEqualNumbers(
        summary.cancelledConversions,
        storage.canceledConversions.length,
        'cancelledConversions',
      );
      expectEqualNumbers(
        summary.tokensSold,
        storage.executedConversionsTotal,
      );

    }
  }).timeout(10000);

}
