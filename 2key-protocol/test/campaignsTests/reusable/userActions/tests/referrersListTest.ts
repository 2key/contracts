import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {campaignTypes} from "../../../../constants/smallConstants";

export default function referrersListTest(
  {
    storage,
    userKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  if (
    storage.campaignType === campaignTypes.acquisition
    || storage.campaignType === campaignTypes.donation
  )
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

        const referrers = storage.campaignType === campaignTypes.acquisition
          ? (await protocol.AcquisitionCampaign
            .getReferrersForConverter(campaignAddress, address))
          : (await protocol.DonationCampaign
            .getRefferrersToConverter(campaignAddress, address, web3Address));

        expect(referrers.length).to.be.eq(storageReferrers.length);
        expect(referrers).to.have.members(storageReferrers);
      }
    );
}
