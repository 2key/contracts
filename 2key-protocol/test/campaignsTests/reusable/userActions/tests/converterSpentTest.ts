import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import donationOnly from "../checks/donationOnly";
import availableUsers from "../../../../constants/availableUsers";
import TestDonationConversion from "../../../../helperClasses/TestDonationConversion";

export default function converterSpentTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  donationOnly(storage.campaignType);

  it('should get how much user have spent', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    let amountSpent = await protocol.DonationCampaign.getAmountConverterSpent(campaignAddress, address);
    expect(amountSpent).to.be.equal(user.executedConversionsTotal);
  }).timeout(60000);
}
