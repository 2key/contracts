import availableUsers from "../../constants/availableUsers";
import {expect} from "chai";
import {ipfsRegex} from "../../helpers/regExp";
import {campaignUserActions} from "../constants/constants";
import {prepareNumberForCompare, rewardCalc} from "../helpers/numberHelpers";

export default function userTests(
  {
    userKey, refererKey,
    storage, actions, cut,
    cutChain, contribution,
    campaignData,
  }: {
    userKey: string,
    refererKey: string,
    actions: Array<string>,
    campaignData,
    storage: any,
    contribution?: number,
    cut?: number,
    cutChain?: Array<number>,
  }
): void {

  if (actions.includes(campaignUserActions.visit)) {
    it(`should visit campaign as ${userKey}`, async () => {
      const {web3: {address: refAddress}} = availableUsers[refererKey];
      const {protocol} = availableUsers[userKey];
      const {campaignAddress, links: {[refererKey]: refLink}, campaign: {contractor}} = storage;

      await protocol.AcquisitionCampaign
        .visit(campaignAddress, refLink.link, refLink.fSecret);
      const linkOwnerAddress = await protocol.PlasmaEvents.getVisitedFrom(
        campaignAddress, contractor, protocol.plasmaAddress,
      );
      expect(linkOwnerAddress).to.be.eq(refAddress);
    }).timeout(60000);

    if (cutChain) {
      it(`should check correct referral value after visit by ${userKey}`, async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress, links: {[refererKey]: refLink}} = storage;

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
      const {campaignAddress, links: {[refererKey]: refLink}} = storage;

      const hash = await protocol.AcquisitionCampaign.join(
        campaignAddress,
        address, {
          cut,
          referralLink: refLink.link,
          fSecret: refLink.fSecret,
        });

      storage.links[userKey] = hash;

      expect(ipfsRegex.test(hash.link)).to.be.eq(true);
    }).timeout(60000);

    it(`should check is ${userKey} joined by ${refererKey} link`, async () => {
      const {protocol} = availableUsers[userKey];
      const {protocol: refProtocol} = availableUsers[refererKey];
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

    it(`should decrease available tokens amount to purchased amount by ${userKey}`, async () => {
      const {protocol, web3: {address}} = availableUsers[userKey];
      const {campaignAddress, links: {[refererKey]: refLink}} = storage;

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
// TODO: replace with between +-0.01
      expect(
        prepareNumberForCompare(amountOfTokensAfterConvert)
      ).to.be
        .eq(
          prepareNumberForCompare(initialAmountOfTokens - amountOfTokensForPurchase)
        );
      if (campaignData.isKYCRequired) {
        storage.envData.pendingConverters.push(address);
        storage.counters.pendingConverters += 1;
        storage.counters.pendingConversions += 1;
      }
    }).timeout(60000);
  }
  /**
   * TODO: conversion id or index should be provided as param
   * TODO: check is conversion canceled, check for current user balance (maybe deps issue)
   */
  if (actions.includes(campaignUserActions.cancelConvert)) {
    if (!campaignData.isKYCRequired) {
      throw new Error(
        `${campaignUserActions.cancelConvert} action available only for campaigns with verification`
      );
    }
    // Only for case when KYC=true, otherwise conversions will be executed automatically
    it('buyer should cancel his conversion and ask for refund', async () => {
      const {protocol, address, web3: {address: web3Address}} = availableUsers[userKey];
      const {campaignAddress} = storage;
      const conversionIndex = 0;

      const conversionIds = await protocol.AcquisitionCampaign.getConverterConversionIds(
        campaignAddress, address, web3Address,
      );

      expect(conversionIds.length).to.be.gt(0);

      const txHash = await protocol.AcquisitionCampaign.converterCancelConversion(
        campaignAddress,
        conversionIds[conversionIndex],
        web3Address,
      );
      await protocol.Utils.getTransactionReceiptMined(txHash);

      const conversionObj = await protocol.AcquisitionCampaign.getConversion(
        campaignAddress, conversionIndex, web3Address,
      );

      storage.counters.cancelledConversions += 1;
      storage.counters.pendingConversions -= 1;

      // todo: assert
      // expect()
    }).timeout(60000);
  }
}
