import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {campaignTypes, conversionStatuses, feePercent} from "../../../../constants/smallConstants";
import kycRequired from "../checks/kycRequired";
import ITestConversion from "../../../../typings/ITestConversion";

export default function executeConversionTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  if (storage.campaignType !== campaignTypes.cpc) {
    kycRequired(campaignData.isKYCRequired);
  }

  if (storage.campaignType === campaignTypes.cpc) {
    it('should approve converter from maintainer and distribute rewards', async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {protocol: converterProtocol} = availableUsers[secondaryUserKey];
      const {campaignAddress} = storage;
      const user = storage.getUser(secondaryUserKey);
      const {pendingConversions} = user;

      expect(pendingConversions.length, 'any pending conversions for execute').to.be.gt(0);
      const conversionForCheck = pendingConversions[0];

      await protocol.CPCCampaign.approveConverterAndExecuteConversion(
        campaignAddress, converterProtocol.plasmaAddress, protocol.plasmaAddress
      );
      await new Promise(resolve => setTimeout(resolve, 1000));

      const lastConversion = await converterProtocol.CPCCampaign.getConversion(
        campaignAddress,
        conversionForCheck.id
      );

      expect(lastConversion.conversionState).to.be.eq(conversionStatuses.executed);
      expect(lastConversion.bountyPaid).to.be.eq(campaignData.bountyPerConversionWei * (1 - feePercent));

      conversionForCheck.data = lastConversion;
      storage.processConversion(user, conversionForCheck, campaignData.incentiveModel);
    }).timeout(60000);
  } else {
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
}
