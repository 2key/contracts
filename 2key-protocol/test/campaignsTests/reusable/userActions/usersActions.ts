import {campaignUserActions} from "../../../constants/campaignUserActions";
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
import checkStatisticTest from "./tests/checkStatisticTest";
import checkConverterMetricTest from "./tests/checkConverterMetricTest";
import checkERC20BalanceTest from "./tests/checkERC20BalanceTest";
import functionParamsInterface from "./typings/functionParamsInterface";
import converterSpentTest from "./tests/converterSpentTest";
import referrersListTest from "./tests/referrersListTest";
import checkAvailableDonationTest from "./tests/checkAvailableDonationTest";
import checkTotalReferrerRewardTest from "./tests/checkTotalReferrerRewardTest";
import checkContractorBalanceAndProceedsTest from "./tests/checkContractorBalanceAndProceedsTest";
import referrerRewardStatsTest from "./tests/referrerRewardStatsTest";
import lockContractTest from "./tests/lockContractTest";
import merkleCopyTest from "./tests/merkleCopyTest";
import checkMerkleProofTest from "./tests/checkMerkleProofTest";
import mainChainBalancesSyncTest from "./tests/mainChainBalancesSyncTest";


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
  [campaignUserActions.checkReferrersList]: referrersListTest,
  [campaignUserActions.checkReferrerReward]: checkReferrerRewardTest,
  [campaignUserActions.contractorWithdraw]: contractorWithdrawTest,
  [campaignUserActions.checkStatistic]: checkStatisticTest,
  [campaignUserActions.checkConverterMetric]: checkConverterMetricTest,
  [campaignUserActions.checkERC20Balance]: checkERC20BalanceTest,
  [campaignUserActions.checkContractorBalanceAndProceeds]: checkContractorBalanceAndProceedsTest,
  [campaignUserActions.checkReferrerRewardStats]: referrerRewardStatsTest,

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
   * Donation only tests
   */
  [campaignUserActions.checkConverterSpent]: converterSpentTest,
  [campaignUserActions.checkTotalReferrerReward]: checkTotalReferrerRewardTest,
  [campaignUserActions.checkAvailableDonation]: checkAvailableDonationTest,
  /**
   * cpc only tests
   */
  [campaignUserActions.lockContract]: lockContractTest,
  [campaignUserActions.merkleCopyTest]: merkleCopyTest,
  [campaignUserActions.checkMerkleProof]: checkMerkleProofTest,
  [campaignUserActions.checkMainChainBalancesSync]: mainChainBalancesSyncTest,
};

export default function userTests(
  {
    userKey, secondaryUserKey,
    storage, actions, cut,
    contribution,
    campaignData, expectError
  }: {
    userKey: string,
    secondaryUserKey?: string,
    actions: Array<string>,
    campaignData,
    storage: TestStorage,
    contribution?: number,
    cut?: number,
    expectError?: boolean,
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
    expectError,
  };

  actions.forEach((action) => {
    const method = actionToTest[action];
    if(typeof method !== 'function'){
      throw new Error(`Unknown user action: ${action}`);
    }

    method(functionParams)
  });
}
