import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import TestAcquisitionConversion from "../../../../helperClasses/TestAcquisitionConversion";
import {campaignTypes, feePercent} from "../../../../constants/smallConstants";
import {expect} from "chai";

export default function checkModeratorEarningsTest(
  {
    storage,
    userKey,
    campaignContract,
    campaignData
  }: functionParamsInterface,
) {
  if(storage.campaignType === campaignTypes.cpc){
    it('should get moderator earnings per campaign', async() => {
      const {protocol} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const earnings = await protocol.CPCCampaign.getModeratorEarningsPerCampaign(campaignAddress);
      const calculatedEarnings = (storage.executedConversions.length)
        * campaignData.bountyPerConversionWei
        * feePercent;

      expect(earnings).to.be.equal(calculatedEarnings);
    })
  }else {
    it('should check moderator earnings', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      // const moderatorTotalEarnings = await protocol[campaignContract].getModeratorTotalEarnings(campaignAddress, address);
      const rate = await protocol.UpgradableExchange.get2keySellRate(address);

      const sum: number = storage.executedConversions
        .reduce(
          (accum: number, conversion): number => {
            if (conversion instanceof TestAcquisitionConversion) {
              accum += conversion.data.conversionAmount;
            }
            return accum;
          },
          0,
        );


      // TODO: getModeratorTotalEarnings is deprecated and should be replaced in future
// expectEqualNumbers(moderatorTotalEarnings, sum * feePercent / rate)
    }).timeout(60000);
  }
}
