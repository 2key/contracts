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
    expectError,
  }: functionParamsInterface,
) {
  if (!contribution && [campaignTypes.acquisition, campaignTypes.donation].includes(storage.campaignType)) {
    throw new Error(
      `${campaignUserActions.joinAndConvert} action required parameter missing for user ${userKey}`
    );
  }

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

      if (campaignData.isFiatOnly) {
        const signature = await protocol[campaignContract].getSignatureFromLink(
          refUser.link.link, protocol.plasmaAddress, refUser.link.fSecret);

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].convertOffline(
            campaignAddress, signature, web3Address, web3Address,
            contribution,
          )
        );
      } else {
        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.joinAndConvert(
            campaignAddress,
            conversionAmount,
            refUser.link.link,
            web3Address,
            {fSecret: refUser.link.fSecret},
          )
        );
      }

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

      if (campaignData.isFiatOnly && !campaignData.isKYCRequired) {
        const rate = await protocol.UpgradableExchange.get2keySellRate(web3Address);
        const reward = contribution * campaignData.maxReferralRewardPercentWei / 100 / rate;

        expectEqualNumbers(amountOfTokensAfterConvert, initialAmountOfTokens - amountOfTokensForPurchase - reward);
      } else {
        expectEqualNumbers(amountOfTokensAfterConvert, initialAmountOfTokens - amountOfTokensForPurchase);
      }
      // todo: for case when twoKeyEconomy is custom and KYC isn't required: add check for rewards inventory subtract
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
    it(`should create new conversion for ${userKey} ${expectError ? ' with error' : ''}`, async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const currentUser = storage.getUser(userKey);
      const refUser = storage.getUser(secondaryUserKey);
      let error = false;

      try {
        await protocol.CPCCampaign.joinAndConvert(
          campaignAddress,
          refUser.link.link,
          protocol.plasmaAddress,
          {fSecret: refUser.link.fSecret});
      } catch (e) {
        error = true;
      }

      if (expectError) {
        expect(error).to.be.eq(true);
        return;
      }

      await new Promise(resolve => setTimeout(resolve, 4000));

      const conversionId = await protocol.CPCCampaign.getConversionId(campaignAddress, protocol.plasmaAddress);
      const conversion = await protocol.CPCCampaign.getConversion(campaignAddress, conversionId);

      expect(conversion).to.be.a('object');

      currentUser.refUserKey = secondaryUserKey;
      const conversionObj = new TestCPCConversion(
        conversionId,
        conversion,
      );
      currentUser.addConversion(conversionObj);
      storage.processConversion(currentUser, conversionObj, campaignData.incentiveModel);
    }).timeout(60000);
  }
}
