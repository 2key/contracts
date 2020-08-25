import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {campaignTypes, conversionStatuses, feePercent, userStatuses} from "../../../../constants/smallConstants";
import kycRequired from "../checks/kycRequired";
import ITestConversion from "../../../../typings/ITestConversion";
import TestAcquisitionConversion from "../../../../helperClasses/TestAcquisitionConversion";

export default function executeConversionTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    campaignData,
    campaignContract,
    expectError,
  }: functionParamsInterface,
) {
  if (storage.campaignType !== campaignTypes.cpc) {
    kycRequired(campaignData.isKYCRequired);
  }

  if (storage.campaignType === campaignTypes.cpc) {
    it(
      `should approve ${secondaryUserKey} from maintainer and distribute rewards ${expectError ? ' with error' : ''}`,
      async () => {
      const {protocol} = availableUsers[userKey];
      const {protocol: converterProtocol} = availableUsers[secondaryUserKey];
      const {campaignAddress} = storage;
      const user = storage.getUser(secondaryUserKey);
      const {pendingConversions} = user;
      let error = false;

      expect(pendingConversions.length, 'any pending conversions for execute').to.be.gt(0);
      const conversionForCheck = pendingConversions[0];
      try {
        await protocol.CPCCampaign.approveConverterAndExecuteConversion(
          campaignAddress, converterProtocol.plasmaAddress, protocol.plasmaAddress
        );

        await new Promise(resolve => setTimeout(resolve, 4000));
      } catch (e) {
        error = true;
      }

      if (expectError) {
        expect(error).to.be.eq(true);
        return;
      }

      const bounty = await protocol.CPCCampaign.getTotalBountyAndBountyPerConversion(campaignAddress);

      const lastConversion = await converterProtocol.CPCCampaign.getConversion(
        campaignAddress,
        conversionForCheck.id
      );

      expect(lastConversion.conversionState).to.be.eq(conversionStatuses.executed);
      expect(lastConversion.bountyPaid).to.be.eq(bounty.bountyPerConversion * (1 - feePercent));

      user.status = userStatuses.approved;
      conversionForCheck.data = lastConversion;
      storage.processConversion(user, conversionForCheck, campaignData.incentiveModel);
    }).timeout(60000);
  } else {
    it(`should be able to execute after approve (${userKey})`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const user = storage.getUser(userKey);
      const {approvedConversions} = user;

      expect(approvedConversions.length).to.be.gt(0);

      const conversion: ITestConversion = approvedConversions[0];

      await protocol.Utils.getTransactionReceiptMined(
        await protocol[campaignContract].executeConversion(campaignAddress, conversion.id, address)
      );

      const conversionObj = await protocol[campaignContract].getConversion(
        campaignAddress, conversion.id, address,
      );
      if (storage.campaignType === campaignTypes.acquisition) {
        expect(conversionObj.state).to.be.eq(conversionStatuses.executed);
      } else {
        expect(conversionObj.conversionState).to.be.eq(conversionStatuses.executed);
      }
      conversion.data = conversionObj;

      if(conversion instanceof TestAcquisitionConversion){
        conversion.purchase = await protocol.AcquisitionCampaign.getPurchaseInformation(
          campaignAddress, conversion.id, address
        );
      }

      storage.processConversion(user, conversion, campaignData.incentiveModel);
    }).timeout(60000);
  }
}
