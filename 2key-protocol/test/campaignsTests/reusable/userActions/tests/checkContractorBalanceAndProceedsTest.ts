import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";
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
    const {protocol, web3: {address: web3Address}} = availableUsers[userKey];
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

    const {contractorBalance, contractorTotalProceeds} = await protocol[campaignContract]
      .getContractorBalanceAndTotalProceeds(campaignAddress, web3Address);

    expectEqualNumbers(contractorTotalProceeds, totalProceedsStorage);
    expectEqualNumbers(contractorBalance, totalProceedsStorage);
  }).timeout(60000);
}
