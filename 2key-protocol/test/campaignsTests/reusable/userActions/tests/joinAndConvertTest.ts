import {campaignUserActions} from "../../../constants/constants";
import {campaignTypes} from "../../../../constants/smallConstants";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";
import functionParamsInterface from "../typings/functionParamsInterface";

export default function joinAndConvertTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    campaignData,
    contribution,
    campaignContract,
  }: functionParamsInterface,
) {
  if (!contribution) {
    throw new Error(
      `${campaignUserActions.joinAndConvert} action required parameter missing for user ${userKey}`
    );
  }
  // todo: isFiatOnly = true, error appears: "gas required exceeds allowance or always failing transaction"
  if (storage.campaignType === campaignTypes.acquisition) {
    it(`should decrease available tokens amount to purchased amount by ${userKey}`, async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const currentUser = storage.getUser(userKey);
      const refUser = storage.getUser(secondaryUserKey);
      const conversionAmount = protocol.Utils.toWei((contribution), 'ether');
      const initialAmountOfTokens = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        web3Address
      );


      const {totalTokens: amountOfTokensForPurchase} = await protocol.AcquisitionCampaign.getEstimatedTokenAmount(
        campaignAddress,
        campaignData.isFiatOnly,
        conversionAmount,
      );

      const txHash = await protocol.AcquisitionCampaign.joinAndConvert(
        campaignAddress,
        conversionAmount,
        refUser.link.link,
        web3Address,
        {fSecret: refUser.link.fSecret},
      );

      await protocol.Utils.getTransactionReceiptMined(txHash);

      const amountOfTokensAfterConvert = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        web3Address
      );
      const conversionIds = await protocol[campaignContract].getConverterConversionIds(
        campaignAddress, address, web3Address,
      );

      const conversionId = conversionIds[currentUser.allConversions.length];

      currentUser.refUserKey = secondaryUserKey;
      currentUser.addConversion(
        conversionId,
        await protocol[campaignContract].getConversion(
          campaignAddress, conversionId, web3Address,
        )
      );

      expectEqualNumbers(amountOfTokensAfterConvert, initialAmountOfTokens - amountOfTokensForPurchase);
    }).timeout(60000);
  }

  if (storage.campaignType === campaignTypes.donation) {
    it(`should decrease available tokens amount to purchased amount by ${userKey}`, async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const currentUser = storage.getUser(userKey);
      const refUSer = storage.getUser(secondaryUserKey);

      const initialAmountOfTokens = await protocol.DonationCampaign.getAmountConverterSpent(
        campaignAddress,
        address
      );

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.DonationCampaign.joinAndConvert(
          campaignAddress,
          protocol.Utils.toWei(contribution, 'ether'),
          refUSer.link.link,
          web3Address,
          {fSecret: refUSer.link.fSecret},
        )
      );

      const amountOfTokensAfterConvert = await protocol.DonationCampaign.getAmountConverterSpent(
        campaignAddress,
        address
      );

      const conversionIds = await protocol[campaignContract].getConverterConversionIds(
        campaignAddress, address, web3Address,
      );

      const conversionId = conversionIds[currentUser.allConversions.length];

      currentUser.refUserKey = secondaryUserKey;
      currentUser.addConversion(
        conversionId,
        await protocol[campaignContract].getConversion(
          campaignAddress, conversionId, web3Address,
        ),
      );
      // todo: recheck total amount with conversions from the storage
      expectEqualNumbers(amountOfTokensAfterConvert - initialAmountOfTokens, contribution);
    }).timeout(60000);
  }
}
