import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {campaignTypes, conversionStatuses} from "../../../../constants/smallConstants";
import kycRequired from "../checks/kycRequired";
import ITestConversion from "../../../../typings/ITestConversion";

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
    const user = storage.getUser(userKey);
    const {approvedConversions} = user;

    expect(approvedConversions.length).to.be.gt(0);

    const conversion: ITestConversion = approvedConversions[0];

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].executeConversion(campaignAddress, conversion.id, web3Address)
    );

    const conversionObj = await protocol[campaignContract].getConversion(
      campaignAddress, conversion.id, web3Address,
    );
    if (storage.campaignType === campaignTypes.acquisition) {
      expect(conversionObj.state).to.be.eq(conversionStatuses.executed);
    } else {
      expect(conversionObj.conversionState).to.be.eq(conversionStatuses.executed);
    }
    conversion.data = conversionObj;
    storage.processConversion(user, conversion, campaignData.incentiveModel);
  }).timeout(60000);
}
