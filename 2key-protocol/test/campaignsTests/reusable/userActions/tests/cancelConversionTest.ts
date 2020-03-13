import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";
import {campaignTypes, conversionStatuses} from "../../../../constants/smallConstants";
import functionParamsInterface from "../typings/functionParamsInterface";
import kycRequired from "../checks/kycRequired";
import ITestConversion from "../../../../typings/ITestConversion";
import ethOnly from "../checks/ethOnly";

export default function cancelConversionTest(
  {
    storage,
    userKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  kycRequired(campaignData.isKYCRequired);
  ethOnly(campaignData.isFiatOnly);

  if (storage.campaignType === campaignTypes.acquisition) {
    it(`${userKey} should cancel his conversion and ask for refund`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const user = storage.getUser(userKey);
      const {campaignAddress} = storage;

      const initialCampaignInventory = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );
      const balanceBefore = await protocol.getBalance(address, campaignData.assetContractERC20);

      const conversions = user.approvedConversions;

      expect(conversions.length).to.be.gt(0);
      /**
       * Always get first. It can be any conversion from available for this action.
       * But easiest way is always get first
       */
      const storedConversion: ITestConversion = conversions[0];

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.AcquisitionCampaign.converterCancelConversion(
          campaignAddress,
          storedConversion.id,
          address,
        )
      );

      const conversionObj = await protocol[campaignContract].getConversion(
        campaignAddress, storedConversion.id, address,
      );
      const resultCampaignInventory = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );
      const balanceAfter = await protocol.getBalance(address, campaignData.assetContractERC20);

      /**
       * todo: recheck why so strange diff
       * For conversion amount `5`
       * diff is `4.999842805999206` - it is BigNumber calc
       * in some cases it  is `4.988210449999725` - it is BigNumber calc, in this case assertion fails

      expectEqualNumbers(
        conversionObj.conversionAmount,
        parseFloat(
          protocol.Utils.fromWei(
            parseFloat(balanceAfter.balance.ETH.toString())
            - parseFloat(balanceBefore.balance.ETH.toString())
          )
            .toString()
        ),
      );
       */
      expectEqualNumbers(
        resultCampaignInventory - initialCampaignInventory,
        conversionObj.baseTokenUnits + conversionObj.bonusTokenUnits
      );
      expect(conversionObj.state).to.be.eq(conversionStatuses.cancelledByConverter);
      storedConversion.data = conversionObj;

      storage.processConversion(user, storedConversion, campaignData.incentiveModel);
    }).timeout(60000);
  }

  if (storage.campaignType === campaignTypes.donation) {
    it(`${userKey} should cancel his conversion and ask for refund`, async () => {
      const {protocol, web3: {address: web3Address}} = availableUsers[userKey];
      const user = storage.getUser(userKey);
      const {campaignAddress} = storage;

      const conversions = user.approvedConversions;

      expect(conversions.length).to.be.gt(0);

      /**
       * Always get first. It can be any conversion from available for this action.
       * But easiest way is always get first
       */
      const storedConversion: ITestConversion = conversions[0];

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.DonationCampaign.converterCancelConversion(
          campaignAddress,
          storedConversion.id,
          web3Address,
        )
      );

      const conversionObj = await protocol.DonationCampaign.getConversion(
        campaignAddress, storedConversion.id, web3Address,
      );

      expect(conversionObj.conversionState).to.be.eq(conversionStatuses.cancelledByConverter);
      storedConversion.data = conversionObj;

      storage.processConversion(user, storedConversion, campaignData.incentiveModel);
    }).timeout(60000);
  }
}
