import {expect} from "chai";
import {campaignUserActions} from "../../../constants/constants";
import {campaignTypes} from "../../../../constants/smallConstants";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";
import functionParamsInterface from "../typings/functionParamsInterface";
import TestDonationConversion from "../../../../helperClasses/TestDonationConversion";
import TestAcquisitionConversion from "../../../../helperClasses/TestAcquisitionConversion";
import TestCPCConversion from "../../../../helperClasses/TestCPCConversion";

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
  if (!contribution && [campaignTypes.acquisition, campaignTypes.donation].includes(storage.campaignType)) {
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
      const conversion = new TestAcquisitionConversion(
        conversionId,
        await protocol[campaignContract].getConversion(
          campaignAddress, conversionId, web3Address,
        ),
      );
      currentUser.addConversion(conversion);
      storage.processConversion(currentUser, conversion, campaignData.incentiveModel);

      expectEqualNumbers(amountOfTokensAfterConvert, initialAmountOfTokens - amountOfTokensForPurchase);
    }).timeout(60000);
  }

  if (storage.campaignType === campaignTypes.donation) {
    it(`should create new conversion for ${userKey}`, async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const currentUser = storage.getUser(userKey);
      const refUser = storage.getUser(secondaryUserKey);
      const initialAmountOfTokens = await protocol.DonationCampaign.getAmountConverterSpent(
        campaignAddress,
        address
      );

      const conversionIds = await protocol.DonationCampaign.getConverterConversionIds(
        campaignAddress, address, web3Address,
      );

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.DonationCampaign.joinAndConvert(
          campaignAddress,
          protocol.Utils.toWei(contribution, 'ether'),
          refUser.link.link,
          web3Address,
          {fSecret: refUser.link.fSecret},
        )
      );

      const amountOfTokensAfterConvert = await protocol.DonationCampaign.getAmountConverterSpent(
        campaignAddress,
        address
      );

      const conversionIdsAfter = await protocol.DonationCampaign.getConverterConversionIds(
        campaignAddress, address, web3Address,
      );

      const conversionId = conversionIdsAfter[currentUser.allConversions.length];

      currentUser.refUserKey = secondaryUserKey;
      const conversion = new TestDonationConversion(
        conversionId,
        await protocol.DonationCampaign.getConversion(
          campaignAddress, conversionId, web3Address,
        ),
      );
      currentUser.addConversion(conversion);
      storage.processConversion(currentUser, conversion, campaignData.incentiveModel);

      expectEqualNumbers(conversionIds.length, conversionIdsAfter.length - 1);

      if (!campaignData.isKYCRequired) {
        expectEqualNumbers(amountOfTokensAfterConvert, currentUser.executedConversionsTotal);
        expectEqualNumbers(amountOfTokensAfterConvert - initialAmountOfTokens, contribution);
      }
    }).timeout(60000);
  }

  if (storage.campaignType === campaignTypes.cpc) {
    it(`should create new conversion for ${userKey}`, async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const currentUser = storage.getUser(userKey);
      const refUser = storage.getUser(secondaryUserKey);

      const conversions = currentUser.allConversions;
      const nextID = conversions.length;
        await protocol.CPCCampaign.joinAndConvert(
          campaignAddress,
          refUser.link.link,
          protocol.plasmaAddress,
          {fSecret:refUser.link.fSecret});

      currentUser.refUserKey = secondaryUserKey;

      const conversion = await protocol.CPCCampaign.getConversion(campaignAddress, nextID);
console.log({nextID, conversion});

      expect(conversion).to.be.a('object');

      const conversionObj = new TestCPCConversion(
        nextID,
        conversion,
      );
      currentUser.addConversion(conversionObj);
      storage.processConversion(currentUser, conversionObj, campaignData.incentiveModel);
    }).timeout(60000);
  }
}
