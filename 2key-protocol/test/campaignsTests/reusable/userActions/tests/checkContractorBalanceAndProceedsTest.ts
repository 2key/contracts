import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import TestDonationConversion from "../../../../helperClasses/TestDonationConversion";
import TestAcquisitionConversion from "../../../../helperClasses/TestAcquisitionConversion";

export default function checkContractorBalanceAndProceedsTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {

  it(`should check contractor balance and total earnings for ${userKey}`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const totalProceedsStorage = storage.executedConversions
      .reduce(
        (accum, conversion) => {
          if (conversion instanceof TestDonationConversion) {
            accum += conversion.data.contractorProceeds;
          } else if (conversion instanceof TestAcquisitionConversion) {
            accum += conversion.data.contractorProceedsETHWei;
          }
          return accum;
        },
        0,
      );


    const resp = await protocol[campaignContract]
      .getContractorBalanceAndTotalProceeds(campaignAddress, address);

    expectEqualNumbers(resp.contractorTotalProceeds, totalProceedsStorage);
    expectEqualNumbers(resp.contractorBalance, totalProceedsStorage);
  }).timeout(5000);
}
