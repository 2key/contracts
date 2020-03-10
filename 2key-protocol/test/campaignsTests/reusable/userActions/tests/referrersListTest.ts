import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {campaignTypes} from "../../../../constants/smallConstants";

export default function referrersListTest(
  {
    storage,
    userKey,
    secondaryUserKey,
  }: functionParamsInterface,
) {
  it(`should check referrers chain from user ${userKey}`,
    async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const user = storage.getUser(userKey);
      const storageReferrers = storage.getReferralsForUser(user)
        .map(({id}) => {
          const {protocol: {plasmaAddress}} = availableUsers[id];
          return plasmaAddress;
        });
      let referrers;
      switch (storage.campaignType) {
        case campaignTypes.acquisition:
          referrers = (await protocol.AcquisitionCampaign
            .getReferrersForConverter(campaignAddress, address));
          break;
        case campaignTypes.donation:
          referrers = (await protocol.DonationCampaign
            .getRefferrersToConverter(campaignAddress, address, web3Address));
          break;
        case campaignTypes.cpc:
          referrers = await protocol.CPCCampaign.getReferrers(campaignAddress, protocol.plasmaAddress);
          break;
        default:
          throw new Error('Unknown campaign type');
      }

      expect(referrers.length).to.be.eq(storageReferrers.length);
      expect(referrers).to.have.members(storageReferrers);
    }
  ).timeout(60000);
}
