import {expect} from "chai";
import {campaignUserActions} from "../../../../constants/campaignUserActions";
import {campaignTypes} from "../../../../constants/smallConstants";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";
import functionParamsInterface from "../typings/functionParamsInterface";
import TestDonationConversion from "../../../../helperClasses/TestDonationConversion";
import TestAcquisitionConversion from "../../../../helperClasses/TestAcquisitionConversion";
import TestCPCConversion from "../../../../helperClasses/TestCPCConversion";

/**
 * Donation and Acquisition campaigns conversions expect ether on converter balance
 * Amount should be `conversion amount` + `gasPrice of TX`
 */

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
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const currentUser = storage.getUser(userKey);
      const refUser = storage.getUser(secondaryUserKey);
      /**
       * Return total amount of depts, but should be for specific conversion
       * Potential error
       */
      const userDeptsBefore = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);

      const initialAmountOfTokens = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      const {totalTokens: amountOfTokensForPurchase} = await protocol.AcquisitionCampaign.getEstimatedTokenAmount(
        campaignAddress,
        campaignData.isFiatOnly,
        protocol.Utils.toWei((contribution - userDeptsBefore), 'ether'),
      );

      if (campaignData.isFiatOnly) {
        const signature = await protocol[campaignContract].getSignatureFromLink(
          refUser.link.link, protocol.plasmaAddress, refUser.link.fSecret);

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].convertOffline(
            campaignAddress, signature, address, address,
            contribution,
          )
        );
      } else {
        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.joinAndConvert(
            campaignAddress,
            protocol.Utils.toWei(contribution, 'ether'),
            refUser.link.link,
            address,
            {fSecret: refUser.link.fSecret},
          )
        );
      }

      const amountOfTokensAfterConvert = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );


      const conversionIds = await protocol[campaignContract].getConverterConversionIds(
        campaignAddress, address, address,
      );

      const conversionId = conversionIds[currentUser.allConversions.length];

      currentUser.refUserKey = secondaryUserKey;
      const conversion = new TestAcquisitionConversion(
        conversionId,
        await protocol[campaignContract].getConversion(
          campaignAddress, conversionId, address,
        ),
      );
      currentUser.addConversion(conversion);
      storage.processConversion(currentUser, conversion, campaignData.incentiveModel);
      const userDeptsAfter = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);

      if (userDeptsBefore > 0) {
        expect(userDeptsAfter).to.be.lt(userDeptsBefore)
      }

      if (campaignData.isFiatOnly && !campaignData.isKYCRequired) {
        const rate = await protocol.UpgradableExchange.get2keySellRate(address);
        const reward = contribution * campaignData.maxReferralRewardPercentWei / 100 / rate;

        expectEqualNumbers(amountOfTokensAfterConvert, initialAmountOfTokens - amountOfTokensForPurchase - reward);
      } else {
        expectEqualNumbers(amountOfTokensAfterConvert, initialAmountOfTokens - amountOfTokensForPurchase);
      }
    }).timeout(10000);
  }

  if (storage.campaignType === campaignTypes.donation) {
    it(`should create new conversion for ${userKey}`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const currentUser = storage.getUser(userKey);
      const refUser = storage.getUser(secondaryUserKey);
      const userDeptsBefore = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);
      const initialAmountOfTokens = await protocol.DonationCampaign.getAmountConverterSpent(
        campaignAddress,
        address
      );

      const conversionIds = await protocol.DonationCampaign.getConverterConversionIds(
        campaignAddress, address, address,
      );

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.DonationCampaign.joinAndConvert(
          campaignAddress,
          protocol.Utils.toWei(contribution, 'ether').toString(),
          refUser.link.link,
          address,
          {fSecret: refUser.link.fSecret},
        )
      );

      const amountOfTokensAfterConvert = await protocol.DonationCampaign.getAmountConverterSpent(
        campaignAddress,
        address
      );

      const conversionIdsAfter = await protocol.DonationCampaign.getConverterConversionIds(
        campaignAddress, address, address,
      );

      const conversionId = conversionIdsAfter[currentUser.allConversions.length];

      currentUser.refUserKey = secondaryUserKey;
      const conversion = new TestDonationConversion(
        conversionId,
        await protocol.DonationCampaign.getConversion(
          campaignAddress, conversionId, address,
        ),
      );

      currentUser.addConversion(conversion);
      storage.processConversion(currentUser, conversion, campaignData.incentiveModel);

      expectEqualNumbers(conversionIds.length, conversionIdsAfter.length - 1);
      expectEqualNumbers(conversion.data.conversionAmount, contribution - userDeptsBefore);

      if (userDeptsBefore > 0) {
        const userDeptsAfter = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);
        expect(userDeptsAfter).to.be.lt(userDeptsBefore);
      }

      if (!campaignData.isKYCRequired) {
        expectEqualNumbers(amountOfTokensAfterConvert, currentUser.executedConversionsTotal);
        expectEqualNumbers(
          amountOfTokensAfterConvert - initialAmountOfTokens,
          contribution,
        );
      }
    }).timeout(10000);
  }

  if (storage.campaignType === campaignTypes.cpc) {
    it(`should create new conversion for ${userKey} ${expectError ? ' with error' : ''}`, async () => {
      const {protocol} = availableUsers[userKey];
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
    }).timeout(10000);
  }
}
