import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import donationOnly from "../checks/donationOnly";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";
import {exchangeRates} from "../../../../constants/smallConstants";

export default function checkAvailableDonationTest(
  {
    storage,
    userKey,
    campaignData,
  }: functionParamsInterface,
) {
  donationOnly(storage.campaignType);

  it(`should check how much ${userKey} can donate`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    let leftToDonate = await protocol.DonationCampaign.howMuchUserCanContribute(campaignAddress, address, address);

    let expectedValue = user.executedConversionsTotal;

    if(campaignData.currency == 'USD') {
      expectedValue *= exchangeRates.usd;
    }

    expectEqualNumbers(leftToDonate, campaignData.maxDonationAmount-expectedValue);
  }).timeout(60000);
}
