import availableUsers from "../../constants/availableUsers";
import {expect} from "chai";
import {ipfsRegex} from "../../helpers/regExp";
import {campaignUserActions} from "../constants/constants";
import {expectEqualNumbers, rewardCalc} from "../helpers/numberHelpers";
import TestStorage from "../../helperClasses/TestStorage";
import {
  campaignTypes,
  campaignTypeToInstance,
  conversionStatuses, exchangeRates,
  hedgeRate,
  incentiveModels, userStatuses,
  vestingSchemas
} from "../../constants/smallConstants";
import {daysToSeconds} from "../helpers/dates";
import {calcUnlockingDates, calcWithdrawAmounts} from "../helpers/calcHelpers";
import calculateReferralRewards from "../helpers/calculateReferralRewards";

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
    referralRewards?: { [key: string]: number },
  }
): void {
  const campaignContract = campaignTypeToInstance[storage.campaignType];

  if (actions.includes(campaignUserActions.visit)) {
    it(`should visit campaign as ${userKey}`, async () => {
      const {web3: {address: refAddress}} = availableUsers[secondaryUserKey];
      const {protocol} = availableUsers[userKey];
      const {campaignAddress, campaign: {contractor}} = storage;
      const referralUser = storage.getUser(secondaryUserKey);

      expect(referralUser.link).to.be.a('object');

      await protocol[campaignContract]
        .visit(campaignAddress, referralUser.link.link, referralUser.link.fSecret);

      const linkOwnerAddress = await protocol.PlasmaEvents.getVisitedFrom(
        campaignAddress, contractor, protocol.plasmaAddress,
      );
      expect(linkOwnerAddress).to.be.eq(refAddress);
    }).timeout(60000);
  }
  // todo: not sure that this method is relevant, much better to check ref rewards after conversion execution
  if (
    campaignData.incentiveModel === incentiveModels.manual
    && actions.includes(campaignUserActions.checkManualCutsChain)
  ) {
    it(`should check correct referral value after visit by ${userKey}`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const refUser = storage.getUser(secondaryUserKey);

      let maxReward = await protocol[campaignContract].getEstimatedMaximumReferralReward(
        campaignAddress,
        address, refUser.link.link, refUser.link.fSecret,
      );

      /**
       * on this stage user didn't select link owner as referral
       */
      const cutChain = [...storage.getReferralsForUser(refUser), refUser]
        .reverse()
        .map(({cut}) => cut / 100);

      const initialPercent = storage.campaignType === campaignTypes.donation
        ? campaignData.maxReferralRewardPercent
        : campaignData.maxReferralRewardPercentWei;

      expectEqualNumbers(maxReward, rewardCalc(initialPercent, cutChain));
    }).timeout(60000);
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
      const currentUser = storage.getUser(userKey);
      const refUser = storage.getUser(secondaryUserKey);

      const linkObject = await protocol[campaignContract].join(
        campaignAddress,
        address, {
          cut,
          referralLink: refUser.link.link,
          fSecret: refUser.link.fSecret,
        }
      );

      currentUser.cut = cut;
      currentUser.link = linkObject;
      currentUser.refUserKey = secondaryUserKey;

      expect(ipfsRegex.test(linkObject.link)).to.be.eq(true);
    }).timeout(60000);

    it(`should check is ${userKey} joined by ${secondaryUserKey} link`, async () => {
      const {protocol} = availableUsers[userKey];
      const user = storage.getUser(userKey);
      const {protocol: refProtocol} = availableUsers[user.refUserKey];
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

  // todo: possible to user correctly only after correct storage implementation
  // if (actions.includes(campaignUserActions.checkConverterSpent)) {
  //   if (storage.campaignType !== campaignTypes.donation) {
  //     throw new Error(`${campaignUserActions.checkConverterSpent} action available only for donation`)
  //   }
  //
  //   it('should get how much user have spent', async () => {
  //     const {protocol, address} = availableUsers[userKey];
  //     const {campaignAddress} = storage;
  //
  //     const userSpent = 0;
  //
  //     let amountSpent = await protocol.DonationCampaign.getAmountConverterSpent(campaignAddress, address);
  //     expect(amountSpent).to.be.equal(userSpent);
  //   }).timeout(60000);
  // }

  /**
   * TODO: conversion id or index should be provided as param
   * We had a plan to compare balance before and after but it will be too complex
   * protocol.getBalance returns one of type number | string | BigNumber
   */
  if (campaignData.isKYCRequired) {

    // Only for case when KYC=true, otherwise conversions will be executed automatically
    if (actions.includes(campaignUserActions.cancelConvert)) {
      it(`${userKey} should cancel his conversion and ask for refund`, async () => {
        const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
        const user = storage.getUser(userKey);
        const {campaignAddress} = storage;

        const initialCampaignInventory = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
          campaignAddress,
          address
        );
        const balanceBefore = await protocol.getBalance(web3Address, campaignData.assetContractERC20);

        const conversions = campaignData.isFiatConversionAutomaticallyApproved
          ? user.approvedConversions
          : user.pendingConversions;

        expect(conversions.length).to.be.gt(0);

        /**
         * Always get first. It can be any conversion from available for this action.
         * But easiest way is always get first
         */
        const storedConversion = conversions[0];

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].converterCancelConversion(
            campaignAddress,
            storedConversion.id,
            web3Address,
          )
        );

        const conversionObj = await protocol[campaignContract].getConversion(
          campaignAddress, storedConversion.id, web3Address,
        );
        const resultCampaignInventory = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(
          campaignAddress,
          address
        );
        const balanceAfter = await protocol.getBalance(web3Address, campaignData.assetContractERC20);

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

        Object.assign(storedConversion, conversionObj);
      }).timeout(60000);
    }

    if (actions.includes(campaignUserActions.checkPendingConverters)) {
      it('should check pending converters', async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress} = storage;

        const addresses = await protocol[campaignContract].getAllPendingConverters(campaignAddress, address);

        const pendingUsersAddresses = storage.pendingUsers
          .map(({id}) => availableUsers[id].web3.address);

        expect(addresses.length).to.be.eq(pendingUsersAddresses.length);
        expect(addresses).to.have.members(pendingUsersAddresses);
      }).timeout(60000);

    }

    if (actions.includes(campaignUserActions.approveConverter)) {
      it(`should approve ${secondaryUserKey} converter`, async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress} = storage;
        const {address: secAddress} = availableUsers[secondaryUserKey];
        const userForApprove = storage.getUser(secondaryUserKey);

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].approveConverter(campaignAddress, secAddress, address),
        );

        userForApprove.status = userStatuses.approved;

        const approved = await protocol[campaignContract].getApprovedConverters(campaignAddress, address);
        const pending = await protocol[campaignContract].getAllPendingConverters(campaignAddress, address);

        const pendingUsersAddresses = storage.pendingUsers
          .map(({id}) => availableUsers[id].web3.address);
        const approvedUsersAddresses = storage.approvedUsers
          .map(({id}) => availableUsers[id].web3.address);

        expect(approved.length).to.be.eq(approvedUsersAddresses.length);
        expect(approved).to.have.members(approvedUsersAddresses);
        expect(pending.length).to.be.eq(pendingUsersAddresses.length);
        expect(pending).to.have.members(pendingUsersAddresses);
      }).timeout(60000);
    }

    if (actions.includes(campaignUserActions.rejectConverter)) {
      it(`should reject ${secondaryUserKey} converter`, async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {address: warAddress} = availableUsers[secondaryUserKey];
        const {campaignAddress} = storage;
        const userForReject = storage.getUser(secondaryUserKey);

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].rejectConverter(campaignAddress, warAddress, address)
        );

        userForReject.status = userStatuses.rejected;
        const rejected = await protocol[campaignContract].getAllRejectedConverters(campaignAddress, address);
        const pending = await protocol[campaignContract].getAllPendingConverters(campaignAddress, address);


        const pendingUsersAddresses = storage.pendingUsers
          .map(({id}) => availableUsers[id].web3.address);
        const rejectedUsersAddresses = storage.rejectedUsers
          .map(({id}) => availableUsers[id].web3.address);


        expect(rejected.length).to.be.eq(rejectedUsersAddresses.length);
        expect(rejected).to.have.members(rejectedUsersAddresses);
        expect(pending.length).to.be.eq(pendingUsersAddresses.length);
        expect(pending).to.have.members(pendingUsersAddresses);
      }).timeout(60000);
    }

    if (actions.includes(campaignUserActions.checkRestrictedConvert)) {
      it(`should produce an error on conversion from rejected user (${secondaryUserKey})`, async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress} = storage;
        const {refUserKey} = storage.getUser(userKey);
        const {link: refLink} = storage.getUser(refUserKey);
        let error = false;

        try {
          await protocol.Utils.getTransactionReceiptMined(
            await protocol[campaignContract].joinAndConvert(
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
        const {approvedConversions} = storage.getUser(userKey);

        expect(approvedConversions.length).to.be.gt(0);

        const conversion = approvedConversions[0];

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].executeConversion(campaignAddress, conversion.id, web3Address)
        );


        const conversionObj = await protocol[campaignContract].getConversion(
          campaignAddress, conversion.id, web3Address,
        );

        expect(conversionObj.state).to.be.eq(conversionStatuses.executed);

        Object.assign(conversion, conversionObj);
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
      const user = storage.getUser(userKey);
      const distributionShiftInSeconds = daysToSeconds(
        campaignData.bonusTokensVestingStartShiftInDaysFromDistributionDate,
      );
      const portionIntervalInSeconds = daysToSeconds(
        campaignData.numberOfDaysBetweenPortions,
      );
      const withBase = campaignData.vestingAmount === vestingSchemas.baseAndBonus;
      let portionsQty = campaignData.numberOfVestingPortions;

      if (campaignData.maxConverterBonusPercentWei === 0 && !withBase) {
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

      expect(user.executedConversions.length).to.be.gt(0);

      const conversion = user.executedConversions[0];

      const conversionObj = await protocol[campaignContract].getConversion(
        campaignAddress, conversion.id, web3Address,
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

      const purchase = await protocol[campaignContract].getPurchaseInformation(
        campaignAddress, conversion.id, web3Address
      );

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
      conversion.purchase = purchase;
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.hedgingEth)) {
    it(`should hedging all available ether (${userKey})`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];

      const {balance: {ETH}} = await protocol.getBalance(protocol.twoKeyUpgradableExchange.address);
      const amountForHedge = parseFloat(ETH.toString());

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.UpgradableExchange.startHedgingEth(
          amountForHedge, hedgeRate, address
        ),
      );

      const upgradableExchangeBalanceAfter = await protocol.getBalance(protocol.twoKeyUpgradableExchange.address);

      // send to hedging all available ether
      expect(upgradableExchangeBalanceAfter.balance.ETH.toString()).to.be.eq('0');
    }).timeout(50000);
  }

  if (actions.includes(campaignUserActions.checkCampaignSummary)) {
    /**
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

      const summary = await protocol[campaignContract].getCampaignSummary(campaignAddress, address);

      expectEqualNumbers(
        summary.pendingConverters,
        storage.pendingUsers.length,
      );
      expectEqualNumbers(
        summary.approvedConverters,
        storage.approvedUsers.length,
      );
      expectEqualNumbers(
        summary.rejectedConverters,
        storage.rejectedUsers.length,
      );
      expectEqualNumbers(
        summary.pendingConversions,
        storage.pendingConversions.length,
      );
      expectEqualNumbers(
        summary.approvedConversions,
        storage.approvedConversions.length,
      );
      expectEqualNumbers(
        summary.cancelledConversions,
        storage.canceledConversions.length,
      );
      expectEqualNumbers(
        summary.rejectedConversions,
        storage.rejectedConversions.length,
      );
      expectEqualNumbers(
        summary.executedConversions,
        storage.executedConversions.length,
      );
      expectEqualNumbers(
        summary.tokensSold,
        storage.tokensSold,
      );
      expectEqualNumbers(
        summary.totalBounty,
        storage.totalBounty,
      );
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.checkModeratorEarnings)) {
    // todo: conversionAmount(ETH) * 0.02 * usdRate * rateUsd2key
    it('should check moderator earnings', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      let moderatorTotalEarnings = await protocol[campaignContract].getModeratorTotalEarnings(campaignAddress, address);
      console.log('Moderator total earnings in 2key-tokens are: ' + moderatorTotalEarnings);
      // Moderator total earnings in 2key-tokens are: 163.33333333333334
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.withdrawTokens)) {
    it('should withdraw tokens', async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const user = storage.getUser(userKey);
      const executedConversions = user.executedConversions;

      expect(executedConversions.length).to.be.gt(0);

      const portionIndex = 0;

      const conversionIds = await protocol[campaignContract].getConverterConversionIds(
        campaignAddress, address, web3Address,
      );
      const conversion = executedConversions[0];
      const balanceBefore = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, address);

      await protocol.Utils.getTransactionReceiptMined(
        await protocol[campaignContract].withdrawTokens(
          campaignAddress,
          conversion.id,
          portionIndex,
          web3Address,
        )
      );

      const balanceAfter = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, address);
      const purchase = await protocol[campaignContract].getPurchaseInformation(campaignAddress, conversion.id, web3Address);
      const withdrawnContract = purchase.contracts[portionIndex];

      expectEqualNumbers(withdrawnContract.amount, balanceAfter - balanceBefore);
      expect(withdrawnContract.withdrawn).to.be.eq(true);

      conversion.purchase = purchase;
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

      const withdrawable = await protocol[campaignContract].getAmountReferrerCanWithdraw(
        campaignAddress, secondaryAddress, address,
      );
      /*
      executed conversion: maxReferralReward2key = 1666.6666666666667

      {
       balance2key: 1666.6666666666667,
       balanceDAI: 909.0909090517757
      }
       */
      expectEqualNumbers(withdrawable.balance2key, storage.totalBounty);
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.contractorWithdraw)) {
    it('should contractor withdraw his earnings', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      await protocol.Utils.getTransactionReceiptMined(
        await protocol[campaignContract].contractorWithdraw(campaignAddress, address)
      );

      const contractorBalance = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

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
        await protocol[campaignContract].moderatorAndReferrerWithdraw(
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

  if (actions.includes(campaignUserActions.checkReferrerReward)) {
    /**
     *
     * Keep in mind that this function doesn't expect different converters for one referrer
     *      u2 -- u3 (with conversion)
     *    /
     * u1 - u4 -- u5 (with conversion)
     *
     * For fix this easiest way to store reward in users objects right after execution
     */
    it(`should check is referrers reward calculated correctly for ${userKey} conversions`, async () => {
      const {protocol} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const user = storage.getUser(userKey);
      const referrals = storage.getReferralsForUser(user);
      const expectedRewards = calculateReferralRewards(campaignData.incentiveModel, referrals, user.referralsReward);
      const referralKeys = Object.keys(expectedRewards);

      for (let i = 0; i < referralKeys.length; i += 1) {
        const refKey = referralKeys[i];
        const expectReward = expectedRewards[refKey];
        const {protocol: {plasmaAddress}} = availableUsers[refKey];

        const refReward = await protocol.AcquisitionCampaign
          .getReferrerPlasmaBalance(campaignAddress, plasmaAddress);

        expectEqualNumbers(
          refReward,
          expectReward,
        );
      }
    }).timeout(60000);
  }


  if (actions.includes(campaignUserActions.checkTotalEarnings)) {
    it('should get moderator total earnings in campaign', async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      const totalEarnings = await protocol[campaignContract].getModeratorTotalEarnings(campaignAddress, address);
      console.log('Moderator total earnings: ' + totalEarnings);
    }).timeout(60000);
  }

  /**
   {
    amountConverterSpentETH: 0,
    referrerRewards: 1666.6666666666667,
    tokensBought: 0,
    isConverter: false,
    isReferrer: true,
    isJoined: true,
    username: 'gmail',
    fullName: '7YwD8IUQcly0KwM5Jc+IZw==',
    email: 'RY6B9WJVMQK0tajTtW3jWw==',
    ethereumOf: '0xf3c7641096bc9dc50d94c572bb455e56efc85412',
    converterState: 'NOT_CONVERTER'
  }
   */
  // todo: add assertion or remove
  if (actions.includes(campaignUserActions.checkStatistic)) {
    it(`should get statistics for ${userKey}`, async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      let stats = await protocol[campaignContract].getAddressStatistic(
        campaignAddress,
        address,
        '0x0000000000000000000000000000000000000000',
        {from: web3Address},
      );
      console.log(stats);
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.checkConverterMetric)) {
    /**
     * todo: add totalLocked assertion
     */
    it(`should get converter metrics per campaign`, async () => {
      const {protocol, address} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const user = storage.getUser(userKey);

      expect(user).to.be.a('object');
      const storageMetric = user.converterMetrics;
      const metrics = await protocol[campaignContract].getConverterMetricsPerCampaign(
        campaignAddress, address);

      expectEqualNumbers(metrics.totalBought, storageMetric.totalBought);
      expectEqualNumbers(metrics.totalAvailable, storageMetric.totalAvailable);
      expectEqualNumbers(metrics.totalWithdrawn, storageMetric.totalWithdrawn)
    }).timeout(60000);
  }

  if (actions.includes(campaignUserActions.checkERC20Balance)) {
    // todo: add assert
    if (storage.campaignType === campaignTypes.acquisition) {
      it(`should print balance of left ERC20 on the Acquisition contract`, async () => {
        const {protocol} = availableUsers[userKey];
        const {campaignAddress} = storage;

        let balance = await protocol.ERC20.getERC20Balance(campaignData.assetContractERC20, campaignAddress);
        console.log(balance);
        // 1229614.0350877193 ()
        // 1234000 - 1229614.0350877193 = 4385.96491228
      }).timeout(60000);
    }

    if (storage.campaignType === campaignTypes.donation) {
      it('should proof that the invoice has been issued for executed conversion (Invoice tokens transfered)', async () => {
        const {protocol} = availableUsers[userKey];
        const {address: secondaryUserAddress} = availableUsers[secondaryUserKey];
        // @ts-ignore
        const {campaignAddress, campaign: {invoiceToken}} = storage;

        let balance = await protocol.ERC20.getERC20Balance(invoiceToken, secondaryUserAddress);
        // todo: value should be from storage or params
        let expectedValue = 1;
        if (campaignData.currency == 'USD') {
          expectedValue *= exchangeRates.usd;
        }
        expect(balance).to.be.equal(expectedValue);
      }).timeout(60000);
    }
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
        const {link: refLink} = storage.getUser(secondaryUserKey);
        const {campaignAddress} = storage;

        const signature = await protocol[campaignContract].getSignatureFromLink(
          refLink.link, protocol.plasmaAddress, refLink.fSecret);

        const conversionIdsBefore = await protocol[campaignContract].getConverterConversionIds(
          campaignAddress, address, web3Address);

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].convertOffline(
            campaignAddress, signature, web3Address, web3Address,
            contribution,
          )
        );
        const conversionIdsAfter = await protocol[campaignContract].getConverterConversionIds(
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
        const conversionIds = await protocol[campaignContract].getConverterConversionIds(
          campaignAddress, address, web3Address,
        );
        const conversionId = conversionIds[0];

        await protocol.Utils.getTransactionReceiptMined(
          await protocol[campaignContract].executeConversion(campaignAddress, 4, web3Address)
        );
      }).timeout(60000);
    }
  }
}
