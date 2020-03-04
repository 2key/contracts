import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import TestAcquisitionConversion from "../../../../helperClasses/TestAcquisitionConversion";

export default function checkModeratorEarningsTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  it('should check moderator earnings', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    let moderatorTotalEarnings = await protocol[campaignContract].getModeratorTotalEarnings(campaignAddress, address);

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

    // todo: uncommit when we will know ethTo2KeyRate
// expectEqualNumbers(moderatorTotalEarnings, sum * 0.02* ethTo2KeyRate)
  }).timeout(60000);
}
