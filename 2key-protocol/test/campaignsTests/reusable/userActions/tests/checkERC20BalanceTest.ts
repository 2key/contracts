import functionParamsInterface from "../typings/functionParamsInterface";
import {campaignTypes, exchangeRates} from "../../../../constants/smallConstants";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import TestDonationConversion from "../../../../helperClasses/TestDonationConversion";

export default function checkERC20BalanceTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    campaignData,
  }: functionParamsInterface,
) {
  // todo: add assert
  if (storage.campaignType === campaignTypes.acquisition) {
    it(`should print balance of left ERC20 on the Acquisition contract`, async () => {
      const {protocol} = availableUsers[userKey];
      const {campaignAddress} = storage;

      let balance = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, campaignAddress);
      console.log(balance);
      // 1229614.0350877193 ()
      // 1234000 - 1229614.0350877193 = 4385.96491228
    }).timeout(60000);
  }

  if (storage.campaignType === campaignTypes.donation) {
    it('should proof that the invoice has been issued for executed conversion (Invoice tokens transfered)', async () => {
      const {protocol} = availableUsers[userKey];
      const {address: secondaryUserAddress} = availableUsers[secondaryUserKey];
      // @ts-ignore
      const {campaign: {invoiceToken}} = storage;
      const user = storage.getUser(secondaryUserKey);
      const conversions = user.executedConversions;
      let userSpent = conversions
        .reduce(
          (accum, conversion) => {
            if(conversion instanceof TestDonationConversion){
              accum += conversion.data.tokensBought;
            }

            return accum;
          },
          0,
        );

      let balance = await protocol.ERC20.getERC20Balance(invoiceToken, secondaryUserAddress);

      if (campaignData.currency == 'USD') {
        userSpent *= exchangeRates.usd;
      }
      expect(balance).to.be.equal(userSpent);
    }).timeout(60000);
  }
}
