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
  if (storage.campaignType === campaignTypes.donation) {
    it('should proof that the invoice has been issued for executed conversion (Invoice tokens transfered)', async () => {
      const {protocol} = availableUsers[userKey];
      const {web3: {address: secondaryUserAddress}} = availableUsers[secondaryUserKey];
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
    }).timeout(10000);
  }
}
