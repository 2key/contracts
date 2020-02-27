import availableUsers, {userIds} from "../../constants/availableUsers";
import {expect} from "chai";
import {ipfsRegex} from "../../helpers/regExp";
import {campaignUserActions} from "../constants/constants";
import {expectEqualNumbers, rewardCalc} from "../helpers/numberHelpers";
import TestStorage from "../../helperClasses/TestStorage";
import {
  availableStorageArrays,
  availableStorageCounters,
  availableStorageUserFields
} from "../../constants/storageConstants";
import {conversionStatuses, hedgeRate, incentiveModels, vestingSchemas} from "../../constants/smallConstants";
import {daysToSeconds} from "../helpers/dates";
import {calcUnlockingDates, calcWithdrawAmounts} from "../helpers/calcHelpers";
import web3Switcher from "../../helpers/web3Switcher";
import {getTwoKeyProtocolValues} from "../../helpers/twoKeyProtocol";

export default function userTests(
  {
    userKey, secondaryUserKey,
    storage, actions, cut,
    cutChain, contribution,
    campaignData,
  }: {
    userKey: string,
    secondaryUserKey?: string,
    actions: Array<string>,
    campaignData,
    storage: TestStorage,
    contribution?: number,
    cut?: number,
    cutChain?: Array<number>,
  }
): void {

  if (actions.includes(campaignUserActions.visit)) {
    it(`should visit campaign as ${userKey}`, async () => {
      const {web3: {address: refAddress}} = availableUsers[secondaryUserKey];
      const {protocol} = availableUsers[userKey];
      const {campaignAddress, campaign: {contractor}} = storage;
      const refLink = storage.getUserData(secondaryUserKey, availableStorageUserFields.link);

      await protocol.AcquisitionCampaign
        .visit(campaignAddress, refLink.link, refLink.fSecret);
      const linkOwnerAddress = await protocol.PlasmaEvents.getVisitedFrom(
        campaignAddress, contractor, protocol.plasmaAddress,
      );
      expect(linkOwnerAddress).to.be.eq(refAddress);
    }).timeout(60000);

    if (cutChain && campaignData.incentiveModel === incentiveModels.manual) {
      it(`should check correct referral value after visit by ${userKey}`, async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress} = storage;
        const refLink = storage.getUserData(secondaryUserKey, availableStorageUserFields.link);

        let maxReward = await protocol.AcquisitionCampaign.getEstimatedMaximumReferralReward(
          campaignAddress,
          address, refLink.link, refLink.fSecret,
        );

        expect(maxReward).to.be.eq(
          rewardCalc(
            campaignData.maxReferralRewardPercentWei,
            cutChain,
          ),
        );
      }).timeout(60000);
    }
  }



  if (actions.includes(campaignUserActions.join)) {
    if (!cut) {
      throw new Error(
        `${campaignUserActions.join} action required parameter missing for user ${userKey}`
      );
    }

    it(`should create a join link for ${userKey}`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const refLink = storage.getUserData(secondaryUserKey, availableStorageUserFields.link);

      const hash = await protocol.AcquisitionCampaign.join(
        campaignAddress,
        address, {
          cut,
          referralLink: refLink.link,
          fSecret: refLink.fSecret,
        });

      storage.setUserData(userKey, availableStorageUserFields.link, hash);

      expect(ipfsRegex.test(hash.link)).to.be.eq(true);
    }).timeout(60000);

    it(`should check is ${userKey} joined by ${secondaryUserKey} link`, async () => {
      const {protocol} = availableUsers[userKey];
      const {protocol: refProtocol} = availableUsers[secondaryUserKey];
      const {campaignAddress, campaign: {contractor}} = storage;

      const joinedFrom = await protocol.PlasmaEvents.getJoinedFrom(
        campaignAddress,
        contractor,
        protocol.plasmaAddress,
      );

      expect(joinedFrom).to.eq(refProtocol.plasmaAddress)
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.joinAndConvert)) {
    if (!contribution) {
      throw new Error(
        `${campaignUserActions.joinAndConvert} action required parameter missing for user ${userKey}`
      );
    }
    // todo: isFiatOnly = true, error appears: "gas required exceeds allowance or always failing transaction"

    it(`should decrease available tokens amount to purchased amount by ${userKey}`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const refLink = storage.getUserData(secondaryUserKey, availableStorageUserFields.link);

      const initialAmountOfTokens = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      const {totalTokens: amountOfTokensForPurchase} = await protocol.AcquisitionCampaign.getEstimatedTokenAmount(
        campaignAddress,
        campaignData.isFiatOnly,
        protocol.Utils.toWei((contribution), 'ether')
      );

      const txHash = await protocol.AcquisitionCampaign.joinAndConvert(
        campaignAddress,
        protocol.Utils.toWei(contribution, 'ether'),
        refLink.link,
        address,
        {fSecret: refLink.fSecret},
      );

      await protocol.Utils.getTransactionReceiptMined(txHash);

      const amountOfTokensAfterConvert = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
        campaignAddress,
        address
      );

      expectEqualNumbers(amountOfTokensAfterConvert, initialAmountOfTokens - amountOfTokensForPurchase);

      if (campaignData.isKYCRequired) {
        storage.arrayPush(availableStorageArrays.pendingConverters, address);
        storage.counterIncrease(availableStorageCounters.pendingConversions);
      }
    }).timeout(60000);
  }
  /**
   * TODO: conversion id or index should be provided as param
   * TODO: check for current user balance (maybe deps issue)
   * We had a plan to compare balance before and after but it will be too complex
   * protocol.getBalance returns one of type number | string | BigNumber
   */
  if (campaignData.isKYCRequired) {

    // Only for case when KYC=true, otherwise conversions will be executed automatically
    if (actions.includes(campaignUserActions.cancelConvert)) {
      it(`${userKey} should cancel his conversion and ask for refund`, async () => {
        const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
        const {campaignAddress} = storage;

        const conversionIds = await protocol.AcquisitionCampaign.getConverterConversionIds(
          campaignAddress, address, web3Address,
        );

        expect(conversionIds.length).to.be.gt(0);

        const conversionId = conversionIds[0];

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.converterCancelConversion(
            campaignAddress,
            conversionId,
            web3Address,
          )
        );

        const conversionObj = await protocol.AcquisitionCampaign.getConversion(
          campaignAddress, conversionId, web3Address,
        );

        storage.counterIncrease(availableStorageCounters.cancelledConversions);
        storage.counterDecrease(availableStorageCounters.pendingConversions);

        expect(conversionObj.state).to.be.eq(conversionStatuses.cancelledByConverter);
      }).timeout(60000);
    }

    if (actions.includes(campaignUserActions.checkPendingConverters)) {
      it('should check pending converters', async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress} = storage;

        const addresses = await protocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, address);

        expect(addresses).to.deep.equal(storage.getArray(availableStorageArrays.pendingConverters));
      }).timeout(60000);

    }

    if (actions.includes(campaignUserActions.approveConverter)) {
      it(`should approve ${secondaryUserKey} converter`, async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress} = storage;
        const {address: warAddress, web3: {address: secondaryWeb3Address}} = availableUsers[secondaryUserKey];

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.approveConverter(campaignAddress, warAddress, address),
        );

        storage.arrayRemove(availableStorageArrays.pendingConverters, secondaryWeb3Address);
        storage.arrayPush(availableStorageArrays.approvedConverters, secondaryWeb3Address);

        const approved = await protocol.AcquisitionCampaign.getApprovedConverters(campaignAddress, address);
        const pending = await protocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, address);

        expect(approved)
          .to.have.deep.members(storage.getArray(availableStorageArrays.approvedConverters))
          .to.not.have.members(storage.getArray(availableStorageArrays.pendingConverters));
        expect(pending)
          .to.have.deep.members(storage.getArray(availableStorageArrays.pendingConverters))
          .to.not.have.members(storage.getArray(availableStorageArrays.approvedConverters));
      }).timeout(60000);
    }

    if (actions.includes(campaignUserActions.rejectConverter)) {
      it(`should reject ${secondaryUserKey} converter`, async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {address: warAddress, web3: {address: secondaryWeb3Address}} = availableUsers[secondaryUserKey];
        const {campaignAddress} = storage;

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.rejectConverter(campaignAddress, warAddress, address)
        );

        storage.arrayRemove(availableStorageArrays.pendingConverters, secondaryWeb3Address);
        storage.arrayPush(availableStorageArrays.rejectedConverters, secondaryWeb3Address);

        const rejected = await protocol.AcquisitionCampaign.getAllRejectedConverters(campaignAddress, address);
        const pending = await protocol.AcquisitionCampaign.getAllPendingConverters(campaignAddress, address);

        expect(rejected)
          .to.have.deep.members(storage.getArray(availableStorageArrays.rejectedConverters))
          .to.not.have.members(storage.getArray(availableStorageArrays.pendingConverters));
        expect(pending)
          .to.have.deep.members(storage.getArray(availableStorageArrays.pendingConverters))
          .to.not.have.members(storage.getArray(availableStorageArrays.rejectedConverters));
      }).timeout(60000);
    }

    if (actions.includes(campaignUserActions.checkRestrictedConvert)) {
      it(`should produce an error on conversion from rejected user (${secondaryUserKey})`, async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress} = storage;
        const refLink = storage.getUserData(secondaryUserKey, availableStorageUserFields.link);
        let error = false;
        try {
          await protocol.Utils.getTransactionReceiptMined(
            await protocol.AcquisitionCampaign.joinAndConvert(
              campaignAddress,
              protocol.Utils.toWei(contribution, 'ether'),
              refLink.link,
              address,
              {fSecret: refLink.fSecret},
            )
          );

        } catch {
          error = true;
        }

        expect(error).to.be.eq(true);
      }).timeout(60000);
    }

    if (actions.includes(campaignUserActions.executeConversion)) {
      it(`should be able to execute after approve (${userKey})`, async () => {
        const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
        const {campaignAddress} = storage;

        const conversionIds = await protocol.AcquisitionCampaign.getConverterConversionIds(
          campaignAddress, address, web3Address,
        );

        const conversionId = conversionIds[0];

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.executeConversion(campaignAddress, conversionId, web3Address)
        );

        const conversionObj = await protocol.AcquisitionCampaign.getConversion(
          campaignAddress, conversionId, web3Address,
        );

        expect(conversionObj.state).to.be.eq(conversionStatuses.executed);
      }).timeout(60000);
    }
  }

  if (actions.includes(campaignUserActions.checkConversionPurchaseInfo)) {
    /**
     * BASE_AND_BONUS
     *
     * - check for portions number (numberOfVestingPortions),
     * - check for dates (numberOfDaysBetweenPortions),
     * - amount ( ( base + bonus ) / numberOfVestingPortions)
     * BONUS
     *
     * Base amount totally included to first withdraw contract
     * Portions included only bonus amount divided to portions quantity
     *
     * - check for portions number (numberOfVestingPortions + 1)
     * - check for dates (numberOfDaysBetweenPortions),1),
     * -- [0] = tokenDistributionDate
     * -- [1] = tokenDistributionDate + bonusTokensVestingStartShiftInDaysFromDistributionDate
     * -- [2] = [1] + numberOfDaysBetweenPortions
     * -- etc
     * - amount
     * -- [0] = base tokens amount
     * -- [1] and other = bonus tokens amount / numberOfVestingPortions
     */
    it('should check conversion purchase information', async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const distributionShiftInSeconds = daysToSeconds(
        campaignData.bonusTokensVestingStartShiftInDaysFromDistributionDate,
      );
      const portionIntervalInSeconds = daysToSeconds(
        campaignData.numberOfDaysBetweenPortions,
      );
      const withBase = campaignData.vestingAmount === vestingSchemas.baseAndBonus;
      let portionsQty =  campaignData.numberOfVestingPortions;

      if(campaignData.maxConverterBonusPercentWei === 0 && !withBase){
        // in this case base tokens release in DD, and we don't have any bonus for create portion withdraws
        portionsQty = 0;
      }

      const unlockingDates = calcUnlockingDates(
        campaignData.tokenDistributionDate,
        portionsQty,
        portionIntervalInSeconds,
        distributionShiftInSeconds,
        withBase,
      );
      const conversionIds = await protocol.AcquisitionCampaign.getConverterConversionIds(
        campaignAddress, address, web3Address,
      );
      const conversionId = conversionIds[0];

      const conversionObj = await protocol.AcquisitionCampaign.getConversion(
        campaignAddress, conversionId, web3Address,
      );
      const withdrawAmounts = calcWithdrawAmounts(
        conversionObj.baseTokenUnits,
        conversionObj.bonusTokenUnits,
        portionsQty,
        withBase,
      );
      const withdrawContractsQuantity = withBase
        ? portionsQty
        : portionsQty + 1; // added first

      const purchase = await protocol.AcquisitionCampaign.getPurchaseInformation(campaignAddress, conversionId, web3Address);

      /**
       * todo: looks like bug
       * vestingAmount: BASE_AND_BONUS
       * numberOfVestingPortions = 6
       * purchase.vestingPortions = 5
       */
      // expect(purchase.vestingPortions).to.be.eq(campaignData.numberOfVestingPortions);
      expect(purchase.unlockingDays.length).to.be.eq(withdrawContractsQuantity);
      expect(purchase.unlockingDays).to.deep.equal(unlockingDates);
      expectEqualNumbers(
        purchase.totalTokens,
        conversionObj.bonusTokenUnits + conversionObj.baseTokenUnits,
      );
      expectEqualNumbers(purchase.totalTokens, purchase.bonusTokens + purchase.baseTokens);
      expectEqualNumbers(
        purchase.bonusTokens,
        purchase.baseTokens * campaignData.maxConverterBonusPercentWei / 100,
      );
      for (let i = 0; i < purchase.contracts.length; i += 1) {
        const withdrawItem = purchase.contracts[i];

        expectEqualNumbers(withdrawItem.amount, withdrawAmounts[i]);
      }

      storage.counterIncrease(availableStorageCounters.tokensSold, purchase.totalTokens);
      storage.counterIncrease(availableStorageCounters.totalBounty, conversionObj.maxReferralReward2key);
      storage.counterIncrease(availableStorageCounters.raisedFundsEthWei, conversionObj.conversionAmount);
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.hedgingEth)) {
    it(`should hedging all available ether (${userKey})`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];

      const upgradableExchangeBalance = await protocol.getBalance(protocol.twoKeyUpgradableExchange.address);

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.UpgradableExchange.startHedgingEth(
          parseFloat(upgradableExchangeBalance.balance.ETH.toString()), hedgeRate, address
        ),
      );

      const upgradableExchangeBalanceAfter = await protocol.getBalance(protocol.twoKeyUpgradableExchange.address);

      // send to hedging all available ether
      expect(upgradableExchangeBalanceAfter.balance.ETH.toString()).to.be.eq('0');
    }).timeout(50000);
  }

  if (actions.includes(campaignUserActions.checkCampaignSummary)) {
    /**
     * todo: add assertions for conversions related values, for this we need develop storage logic for store conversions by user
     AcquisitionCampaign:
     {
     approvedConversions: 0
     approvedConverters: 1
     campaignRaisedByNow: 101.1534
     cancelledConversions: 0
     executedConversions: 1
     pendingConversions: 0
     pendingConverters: 0
     raisedFundsEthWei: 0.47
     raisedFundsFiatWei: 0
     rejectedConversions: 0
     rejectedConverters: 0
     tokensSold: 11228.0274
     totalBounty: 0
     uniqueConverters: 1
     }

     DonationCampaign:
     {
     approvedConversions: 0
     approvedConverters: 1
     campaignRaisedByNow: 81.7836
     cancelledConversions: 0
     executedConversions: 1
     pendingConversions: 0
     pendingConverters: 0
     raisedFundsEthWei: 0.38
     rejectedConversions: 0
     rejectedConverters: 0
     tokensSold: 81.7836
     totalBounty: 0
     uniqueConverters: 1
     }
     */
    it('should compare campaign summary with storage', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      const summary = await protocol.AcquisitionCampaign.getCampaignSummary(campaignAddress, address);

      expectEqualNumbers(
        summary.pendingConverters,
        storage.getArray(availableStorageCounters.pendingConverters).length,
      );
      expectEqualNumbers(
        summary.approvedConverters,
        storage.getArray(availableStorageCounters.approvedConverters).length,
      );
      expectEqualNumbers(
        summary.rejectedConverters,
        storage.getArray(availableStorageCounters.rejectedConverters).length,
      );
      expectEqualNumbers(
        summary.tokensSold,
        storage.getCounter(availableStorageCounters.tokensSold),
      );
      expectEqualNumbers(
        summary.totalBounty,
        storage.getCounter(availableStorageCounters.totalBounty),
      );
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.checkModeratorEarnings)) {
    // todo: conversionAmount(ETH) * 0.02 * usdRate * rateUsd2key
    it('should check moderator earnings', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      let moderatorTotalEarnings = await protocol.AcquisitionCampaign.getModeratorTotalEarnings(campaignAddress, address);
      console.log('Moderator total earnings in 2key-tokens are: ' + moderatorTotalEarnings);
      // Moderator total earnings in 2key-tokens are: 163.33333333333334
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.withdrawTokens)) {
    // todo: add balance assertion
    /**
     {
       withdrawn: true,
       amount: 5263.1578947368425,
       unlockDate: 1970-01-01T00:00:01.000Z,
       unlockTimestamp: 1,
       lockupsAddress: '0xb44457f7964e55ef2a4bd292c2f6973832589d4d'
     }
     protocol.getBalance results
     ETH                 2KEY
     before: 1.70991167452e+21, 5.7894736842105263157893e+22
     after:          0          1.7968833333333333333333356e+25
     */
    it('should withdraw tokens', async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const conversionIndex = 0;
      const portionIndex = 0;

      const conversionIds = await protocol.AcquisitionCampaign.getConverterConversionIds(
        campaignAddress, address, web3Address,
      );
      const conversionId = conversionIds[conversionIndex];

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.AcquisitionCampaign.withdrawTokens(
          campaignAddress,
          conversionId,
          portionIndex,
          web3Address,
        )
      );

      const purchase = await protocol.AcquisitionCampaign.getPurchaseInformation(campaignAddress, conversionId, web3Address);

      expect(purchase.isPortionWithdrawn[portionIndex]).to.be.eq(true);
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.checkWithdrawableBalance)) {
    // todo: check amount of available for withdraw
    // todo: calc???? probably we should user numbers from TwoKeyExchangeRateContract test
    // if single in chain  - sum(conversion.base)* maxReferralRewardPercent
    // if chain length > 1  - sum(conversion.base)* cut (from maxReferralRewardPercent)
    it('should check referrer balance after hedging is done so hedge-rate exists', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {address: secondaryAddress} = availableUsers[secondaryUserKey];
      const {campaignAddress} = storage;

      const withdrawable = await protocol.AcquisitionCampaign.getAmountReferrerCanWithdraw(
        campaignAddress, secondaryAddress, address,
      );
      /*
      executed conversion: maxReferralReward2key = 1666.6666666666667

      {
       balance2key: 1666.6666666666667,
       balanceDAI: 909.0909090517757
      }
       */
      expectEqualNumbers(withdrawable.balance2key, storage.getCounter(availableStorageCounters.totalBounty));
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.contractorWithdraw)) {
    it('should contractor withdraw his earnings', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.AcquisitionCampaign.contractorWithdraw(campaignAddress, address)
      );

      const contractorBalance = await protocol.AcquisitionCampaign.getContractorBalance(campaignAddress, address);

      expect(contractorBalance.available).to.be.eq(0);
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.moderatorAndReferrerWithdraw)) {
    // todo: check user referrer balance, what balance should be checked???
    it('should referrer withdraw his balances in 2key-tokens', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      const {balance: before} = await protocol.getBalance(address, campaignData.assetContractERC20);
      await protocol.Utils.getTransactionReceiptMined(
        await protocol.AcquisitionCampaign.moderatorAndReferrerWithdraw(
          campaignAddress,
          false,
          address,
        )
      );
      const {balance: after} = await protocol.getBalance(address, campaignData.assetContractERC20);
console.log(before.ETH.toString(), before['2KEY'].toString());
console.log(after.ETH.toString(), after['2KEY'].toString());

    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.checkTotalEarnings)) {
    it('should get moderator total earnings in campaign', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      const totalEarnings = await protocol.AcquisitionCampaign.getModeratorTotalEarnings(campaignAddress, address);
      console.log('Moderator total earnings: ' + totalEarnings);
    }).timeout(60000);
  }

  // probably useful for referrer
  // todo: add assertion
  if (actions.includes(campaignUserActions.checkStatistic)) {
    it(`should get statistics for ${userKey}`, async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      let stats = await protocol.AcquisitionCampaign.getAddressStatistic(
        campaignAddress,
        address,
        '0x0000000000000000000000000000000000000000',
        {from: web3Address},
      );
      console.log(stats);
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.checkCampaignMetric)) {
    /**
     * todo: assertion
     totalBought(pin):66048.639
     totalAvailable(pin):66048.639
     totalLocked(pin):0
     totalWithdrawn(pin):0
     */
    /**
     { totalBought: 0,
  totalAvailable: 0,
  totalLocked: 0,
  totalWithdrawn: 0 }
     */
    it(`should get converter metrics per campaign`, async () => {
      const {protocol, address} = availableUsers[userKey];
      const {campaignAddress} = storage;

      let metrics = await protocol.AcquisitionCampaign.getConverterMetricsPerCampaign(
        campaignAddress, address);
      console.log(metrics);
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.checkERC20Balance)) {
    // todo: add assert
    it(`should print balance of left ERC20 on the Acquisition contract`, async () => {
      const {protocol} = availableUsers[userKey];
      const {campaignAddress} = storage;

      let balance = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, campaignAddress);
      console.log(balance);
      // 1229614.0350877193 ()
      // 1234000 - 1229614.0350877193 = 4385.96491228
    }).timeout(60000);
  }

  if (campaignData.isFiatOnly) {
    if (actions.includes(campaignUserActions.createOffline)) {
      if (!contribution) {
        throw new Error(
          `${campaignUserActions.joinAndConvert} action required parameter missing for user ${userKey}`
        );
      }
      // todo: what should we check here
      it('should create an offline(fiat) conversion', async () => {
        const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
        const refLink = storage.getUserData(secondaryUserKey, availableStorageUserFields.link);
        const {campaignAddress} = storage;

        const signature = await protocol.AcquisitionCampaign.getSignatureFromLink(
          refLink.link, protocol.plasmaAddress, refLink.fSecret);

        const conversionIdsBefore = await protocol.AcquisitionCampaign.getConverterConversionIds(
          campaignAddress, address, web3Address);

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.convertOffline(
            campaignAddress, signature, web3Address, web3Address,
            contribution,
          )
        );
        const conversionIdsAfter = await protocol.AcquisitionCampaign.getConverterConversionIds(
          campaignAddress, address, web3Address);

        console.log({conversionIdsBefore, conversionIdsAfter});
      }).timeout(60000);
    }

    if (
      actions.includes(campaignUserActions.contractorExecuteConversion)
      && campaignData.isFiatConversionAutomaticallyApproved
      && !campaignData.isKYCRequired
    ) {
      it('should execute conversion from contractor', async () => {
        const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
        const {campaignAddress} = storage;

        // Return empty array for contractor
        const conversionIds = await protocol.AcquisitionCampaign.getConverterConversionIds(
          campaignAddress, address, web3Address,
        );
        const conversionId = conversionIds[0];

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.AcquisitionCampaign.executeConversion(campaignAddress, 4, web3Address)
        );
      }).timeout(60000);
    }
  }
}
