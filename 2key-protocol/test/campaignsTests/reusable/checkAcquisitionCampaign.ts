import '../../constants/polifils';
import {expect} from 'chai';
import availableUsers from "../../constants/availableUsers";
import {IPrivateMetaInformation} from "../../../src/acquisition/interfaces";
import TestStorage from "../../helperClasses/TestStorage";
import {campaignTypes} from "../../constants/smallConstants";
import {expectEqualNumbers} from "../../helpers/numberHelpers";
import getTwoKeyEconomyAddress from "../../helpers/getTwoKeyEconomyAddress";


const timeout = 10000;
export default function checkAcquisitionCampaign(campaignParams, storage: TestStorage) {
  const userKey = storage.contractorKey;

  it('should check campaign type by address', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const campaignType = await protocol.TwoKeyFactory.getCampaignTypeByAddress(campaignAddress);
    expect(campaignType).to.be.equal(campaignTypes.acquisition);
  }).timeout(timeout);

  it('validate non singleton hash', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const nonSingletonHash = await protocol.CampaignValidator.getCampaignNonSingletonsHash(
      campaignAddress
    );
    expect(nonSingletonHash).to.be.equal(protocol.AcquisitionCampaign.getNonSingletonsHash());
  });

  it('check contractor user', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const isContractor: boolean = await protocol.AcquisitionCampaign.isAddressContractor(campaignAddress, address);

    expect(isContractor).to.be.equal(true);
  });

  it('should check moderator address', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const moderatorAddress: string = await protocol.AcquisitionCampaign.getModeratorAddress(campaignAddress, address);

    expect(moderatorAddress).to.be.equal(campaignParams.moderator);
  }).timeout(timeout);

  it('should check currency', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const currency = await protocol.AcquisitionCampaign.getAcquisitionCampaignCurrency(campaignAddress, address);
    expect(currency).to.be.equal(campaignParams.currency);
  }).timeout(timeout);

  if (campaignParams.isFiatOnly) {
    it('should reserve amount for fiat conversion rewards', async () => {
      const {protocol, web3: {address: from}} = availableUsers[userKey];
      const {campaignAddress} = storage;

      const {ethWorth2keys} = await protocol.AcquisitionCampaign.getRequiredRewardsInventoryAmount(
        campaignParams.isFiatOnly,
        !campaignParams.isFiatOnly,
        parseFloat(protocol.Utils.fromWei(campaignParams.campaignHardCapWEI).toString()),
        campaignParams.maxReferralRewardPercentWei,
      );

      await protocol.Utils.getTransactionReceiptMined(
        await protocol.AcquisitionCampaign.specifyFiatConversionRewards(
          campaignAddress,
          parseFloat(protocol.Utils.toWei(ethWorth2keys, 'ether').toString()),
          campaignParams.amount,
          from,
        )
      );

      const areRewardsBoughtWithEther = await protocol.AcquisitionCampaign.checkIfRewardsAreBoughtWithEther(campaignAddress);
      expect(areRewardsBoughtWithEther).to.be.equal(true);
    }).timeout(timeout);
  }

  it('check is campaign validated', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const isValidated = await protocol.CampaignValidator.isCampaignValidated(campaignAddress);

    expect(isValidated).to.be.equal(true);
  }).timeout(timeout);

  it('should get campaign public meta from IPFS', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const campaignMeta = await protocol.AcquisitionCampaign.getPublicMeta(campaignAddress, from);

    expect(campaignMeta.meta.assetContractERC20).to.be.equal(campaignParams.assetContractERC20);
  }).timeout(120000);

  it('should transfer assets to campaign', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const balanceBefore = Number.parseFloat(
      protocol.Utils.fromWei(
        await protocol.AcquisitionCampaign.checkInventoryBalance(campaignAddress, from)
      ).toString()
    );
    const txHash = await protocol.transfer2KEYTokens(
      campaignAddress,
      protocol.Utils.toWei(campaignParams.campaignInventory, 'ether'),
      from,
    );
    await protocol.Utils.getTransactionReceiptMined(txHash);
    const balance = Number.parseFloat(
      protocol.Utils.fromWei(
        await protocol.AcquisitionCampaign.checkInventoryBalance(campaignAddress, from)
      ).toString()
    );

    expectEqualNumbers(
      balance,
      campaignParams.campaignInventory + balanceBefore
    );
  }).timeout(timeout);


  it('should make campaign active', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const txHash = await protocol.AcquisitionCampaign.activateCampaign(campaignAddress, from);

    await protocol.Utils.getTransactionReceiptMined(txHash);

    const isActivated = await protocol.AcquisitionCampaign.isCampaignActivated(campaignAddress);

    expect(isActivated).to.be.equal(true);
  }).timeout(timeout);

  it('should get campaign public link', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const publicLink = await protocol.AcquisitionCampaign.getPublicLinkKey(campaignAddress, from);

    expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
  }).timeout(10000);

  it('should get and decrypt ipfs hash', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    let data: IPrivateMetaInformation = await protocol.AcquisitionCampaign.getPrivateMetaHash(
      campaignAddress, from);

    expect(data.campaignPublicLinkKey).to.be.equal(user.link.link);
  }).timeout(120000);

  it('check available tokens', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const availableAmountOfTokens = await protocol.AcquisitionCampaign.getCurrentAvailableAmountOfTokens(campaignAddress, from);

    if (
      campaignParams.isFiatOnly
      && campaignParams.assetContractERC20 === getTwoKeyEconomyAddress()
    ) {
      const rateAtWhich2KeyIsBought = await protocol.AcquisitionCampaign.getRateAtWhich2KEYWasBoughtFIAT(campaignAddress);
      const campaignHardCap = parseFloat(protocol.Utils.fromWei(campaignParams.campaignHardCapWEI).toString());
      const usdAmount = campaignHardCap * (campaignParams.maxReferralRewardPercentWei /100);

      const amount2key = usdAmount/rateAtWhich2KeyIsBought;

      expectEqualNumbers(
        availableAmountOfTokens,
        campaignParams.campaignInventory
        + amount2key,
      );
    } else {
      expect(availableAmountOfTokens).to.be
        .equal(campaignParams.campaignInventory);
    }
  }).timeout(timeout);
}
