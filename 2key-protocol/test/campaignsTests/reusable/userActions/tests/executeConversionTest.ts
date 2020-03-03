import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {conversionStatuses} from "../../../../constants/smallConstants";
import kycRequired from "../checks/kycRequired";

export default function executeConversionTest(
  {
    storage,
    userKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  kycRequired(campaignData.isKYCRequired);

  it(`should be able to execute after approve (${userKey})`, async () => {
    const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const {approvedConversions} = storage.getUser(userKey);

    expect(approvedConversions.length).to.be.gt(0);

    const conversion = approvedConversions[0];

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].executeConversion(campaignAddress, conversion.id, web3Address)
    );

    const conversionObj = await protocol[campaignContract].getConversion(
      campaignAddress, conversion.id, web3Address,
    );

    expect(conversionObj.state).to.be.eq(conversionStatuses.executed);

    Object.assign(conversion, conversionObj);
  }).timeout(60000);
}
