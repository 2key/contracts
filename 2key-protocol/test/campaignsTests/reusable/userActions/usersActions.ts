import {campaignUserActions} from "../../constants/constants";
import TestStorage from "../../../helperClasses/TestStorage";
import {
  campaignTypeToInstance,
} from "../../../constants/smallConstants";
import joinAndConvertTest from "./tests/joinAndConvertTest";
import joinTest from "./tests/joinTest";
import cancelConversionTest from "./tests/cancelConversionTest";
import checkConversionPurchaseTest from "./tests/checkConversionPurchaseTest";
import checkCampaignSummaryTest from "./tests/checkCampaignSummaryTest";
import withdrawTokensTest from "./tests/withdrawTokensTest";
import approveConverterTest from "./tests/approveConverterTest";
import checkPendingConvertersTest from "./tests/checkPendingConvertersTest";
import checkManualCutsChainTest from "./tests/checkManualCutsChainTest";
import visitTest from "./tests/visitTest";
import rejectConverterTest from "./tests/rejectConverterTest";
import checkRestrictedConversionTest from "./tests/checkRestrictedConversionTest";
import executeConversionTest from "./tests/executeConversionTest";
import hedgingEthTest from "./tests/hedgingEthTest";
import checkModeratorEarningsTest from "./tests/checkModeratorEarningsTest";
import checkWithdrawableBalanceTest from "./tests/checkWithdrawableBalanceTest";
import contractorWithdrawTest from "./tests/contractorWithdrawTest";
import moderatorAndReferrerWithdrawTest from "./tests/moderatorAndReferrerWithdrawTest";
import checkReferrerRewardTest from "./tests/checkReferrerRewardTest";
import checkTotalEarningsTest from "./tests/checkTotalEarningsTest";
import checkStatisticTest from "./tests/checkStatisticTest";
import checkConverterMetricTest from "./tests/checkConverterMetricTest";
import checkERC20BalanceTest from "./tests/checkERC20BalanceTest";
import createOfflineConversionTest from "./tests/createOfflineConversionTest";
import functionParamsInterface from "./typings/functionParamsInterface";
import converterSpentTest from "./tests/converterSpentTest";


const actionToTest: {[key: string]: (params: functionParamsInterface) => void} = {
  [campaignUserActions.visit]: visitTest,
  [campaignUserActions.checkManualCutsChain]: checkManualCutsChainTest,
  [campaignUserActions.join]: joinTest,
  [campaignUserActions.joinAndConvert]: joinAndConvertTest,
  [campaignUserActions.checkConversionPurchaseInfo]: checkConversionPurchaseTest,
  [campaignUserActions.hedgingEth]: hedgingEthTest,
  [campaignUserActions.checkCampaignSummary]: checkCampaignSummaryTest,
  [campaignUserActions.checkModeratorEarnings]: checkModeratorEarningsTest,
  [campaignUserActions.withdrawTokens]: withdrawTokensTest,
  [campaignUserActions.checkWithdrawableBalance]: checkWithdrawableBalanceTest,
  [campaignUserActions.contractorWithdraw]: contractorWithdrawTest,
  [campaignUserActions.moderatorAndReferrerWithdraw]: moderatorAndReferrerWithdrawTest,
  [campaignUserActions.checkReferrerReward]: checkReferrerRewardTest,
  [campaignUserActions.checkTotalEarnings]: checkTotalEarningsTest,
  [campaignUserActions.contractorWithdraw]: contractorWithdrawTest,
  [campaignUserActions.checkStatistic]: checkStatisticTest,
  [campaignUserActions.checkConverterMetric]: checkConverterMetricTest,
  [campaignUserActions.checkERC20Balance]: checkERC20BalanceTest,
  /**
   * KYC only tests
   */
  [campaignUserActions.cancelConvert]: cancelConversionTest,
  [campaignUserActions.checkPendingConverters]: checkPendingConvertersTest,
  [campaignUserActions.approveConverter]: approveConverterTest,
  [campaignUserActions.rejectConverter]: rejectConverterTest,
  [campaignUserActions.checkRestrictedConvert]: checkRestrictedConversionTest,
  [campaignUserActions.executeConversion]: executeConversionTest,
  /**
   * Fiat only tests
   */
  [campaignUserActions.createOffline]: createOfflineConversionTest,
  /**
   * Donation only tests
   */
  [campaignUserActions.checkConverterSpent]: converterSpentTest,
};

export default function userTests(
  {
    userKey, secondaryUserKey,
    storage, actions, cut,
    contribution,
    campaignData,
  }: {
    userKey: string,
    secondaryUserKey?: string,
    actions: Array<string>,
    campaignData,
    storage: TestStorage,
    contribution?: number,
    cut?: number,
  }
): void {
  const campaignContract = campaignTypeToInstance[storage.campaignType];
  const functionParams: functionParamsInterface = {
    storage,
    userKey,
    secondaryUserKey,
    campaignData,
    contribution,
    campaignContract,
    cut,
  };

  actions.forEach((action) => {
    const method = actionToTest[action];
    if(typeof method !== 'function'){
      throw new Error(`Unknown user action: ${action}`);
    }

    method(functionParams)
  });

  if (campaignData.isFiatOnly) {
// todo: recheck probably the same as execute conversion from owner
    /*
    if (
      actions.includes(campaignUserActions.contractorExecuteConversion)
      && campaignData.isFiatConversionAutomaticallyApproved
      && !campaignData.isKYCRequired
    ) {
      it('should execute conversion from contractor', async () => {
        const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
        const {campaignAddress} = storage;

        // Return empty array for contractor
        const conversionIds = await protocol[campaignContract].getConverterConversionIds(
          campaignAddress, address, web3Address,
        );
        const conversionId = conversionIds[0];

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].executeConversion(campaignAddress, 4, web3Address)
        );
      }).timeout(60000);
    }
     */
  }
}
