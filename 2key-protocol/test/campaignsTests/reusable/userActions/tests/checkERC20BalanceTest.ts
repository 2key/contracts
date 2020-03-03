import functionParamsInterface from "../typings/functionParamsInterface";
import {campaignTypes, exchangeRates} from "../../../../constants/smallConstants";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";

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
      const {campaignAddress, campaign: {invoiceToken}} = storage;

      let balance = await protocol.ERC20.getERC20Balance(invoiceToken, secondaryUserAddress);
      // todo: value should be from storage or params
      let expectedValue = 1;
      if (campaignData.currency == 'USD') {
        expectedValue *= exchangeRates.usd;
      }
      expect(balance).to.be.equal(expectedValue);
    }).timeout(60000);
  }
}
