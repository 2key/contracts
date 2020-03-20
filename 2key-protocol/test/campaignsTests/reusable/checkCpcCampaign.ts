import availableUsers, {userIds} from "../../constants/availableUsers";
import {expect} from "chai";
import ICreateCPCTest from "../../typings/ICreateCPCTest";
import {expectEqualNumbers} from "../helpers/numberHelpers";

const TIMEOUT_LENGTH = 60000;

export default function checkCpcCampaign(campaignParams: ICreateCPCTest, storage, maintainerKey: string) {
  const userKey = storage.contractorKey;

  if (
    !campaignParams.etherForRewards
    && !campaignParams.targetClicks
    && campaignParams.bountyPerConversionWei
  ) {
    throw new Error('Required CPC campaign params missing');
  }

  it('should get contractor plasma and public address', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const addresses = await protocol.CPCCampaign.getContractorAddresses(campaignAddress);
    expect(addresses.contractorPlasma).to.be.equal(protocol.plasmaAddress);
    expect(addresses.contractorPublic).to.be.equal(address);
  }).timeout(TIMEOUT_LENGTH);

  it('should check if address is contractor', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];

    const isContractor = await protocol.CPCCampaign.isAddressContractor(storage.campaign.campaignAddressPublic, address);
    expect(isContractor).to.be.equal(true);
  }).timeout(TIMEOUT_LENGTH);

  it('should validate that mirroring is done well on plasma', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const publicMirrorOnPlasma = await protocol.CPCCampaign.getMirrorContractPlasma(campaignAddress);
    expect(publicMirrorOnPlasma).to.be.equal(storage.campaign.campaignAddressPublic);
  }).timeout(TIMEOUT_LENGTH);

  it('should validate that mirroring is done well on public', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const plasmaMirrorOnPublic = await protocol.CPCCampaign.getMirrorContractPublic(
      storage.campaign.campaignAddressPublic,
    );
    expect(plasmaMirrorOnPublic).to.be.equal(campaignAddress);
  }).timeout(TIMEOUT_LENGTH);

  it('should get private meta hash', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(userKey);

    let privateMeta = await protocol.CPCCampaign.getPrivateMetaHash(campaignAddress, protocol.plasmaAddress);
    expect(privateMeta.campaignPublicLinkKey).to.be.equal(user.link.link);
  }).timeout(TIMEOUT_LENGTH);

  if (campaignParams.bountyPerConversionWei) {
    if (Math.round(Math.random())) {
      it('should directly transfer tokens to campaign', async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {protocol: withBalanceProtocol, web3: {address: addressWithBalance}} = availableUsers[userIds.aydnep]; //user with 2keys
        const {campaignAddress, campaign} = storage;
        const inventoryBefore = await protocol.CPCCampaign.getInitialBountyAmount(campaign.campaignAddressPublic);
        let reward;

        if (campaignParams.etherForRewards) {
          const eth2usd = await withBalanceProtocol.TwoKeyExchangeContract.getBaseToTargetRate("USD");
          const boughtRate = await withBalanceProtocol.UpgradableExchange.get2keySellRate(address);

          reward = campaignParams.etherForRewards * eth2usd / boughtRate;
        } else if (campaignParams.targetClicks) {
          reward = campaignParams.bountyPerConversionWei * campaignParams.targetClicks;
        }

        const campaignPublicAddress = await protocol.CPCCampaign.getMirrorContractPlasma(campaignAddress);
        await protocol.Utils.getTransactionReceiptMined(
          await withBalanceProtocol.transfer2KEYTokens(
            campaignPublicAddress,
            withBalanceProtocol.Utils.toWei(reward, 'ether'),
            addressWithBalance,
          )
        );
        await protocol.Utils.getTransactionReceiptMined(
          await protocol.CPCCampaign.addDirectly2KEYAsInventory(campaignAddress, address)
        );
        await new Promise(resolve => setTimeout(resolve, 1000));

        const inventoryAfter = await protocol.CPCCampaign.getInitialBountyAmount(campaign.campaignAddressPublic);

        expectEqualNumbers(
          (inventoryAfter - inventoryBefore),
          reward,
        );
      });
    } else {
      it('should buy referral rewards on public contract by sending ether', async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress, campaign} = storage;
        const inventoryBefore = await protocol.CPCCampaign.getInitialBountyAmount(campaign.campaignAddressPublic);
        const eth2usd = await protocol.TwoKeyExchangeContract.getBaseToTargetRate("USD");
        const boughtRate = await protocol.UpgradableExchange.get2keySellRate(address);

        let reward;
        if (campaignParams.etherForRewards) {
          reward = campaignParams.etherForRewards;
        } else if (campaignParams.targetClicks) {
          reward = campaignParams.bountyPerConversionWei * campaignParams.targetClicks
            / eth2usd * boughtRate;
        }

        await protocol.Utils.getTransactionReceiptMined(
          await protocol.CPCCampaign
            .buyTokensForReferralRewards(
              campaignAddress,
              protocol.Utils.toWei(reward, 'ether'),
              address
            )
        );
        const inventoryAfter = await protocol.CPCCampaign.getInitialBountyAmount(campaign.campaignAddressPublic);

        expectEqualNumbers(
          (inventoryAfter - inventoryBefore),
          reward * eth2usd / boughtRate,
        );
      }).timeout(TIMEOUT_LENGTH);
    }
  }
  it('should set that plasma contract is valid from maintainer', async () => {
    const {protocol} = availableUsers[maintainerKey];
    const {campaignAddress} = storage;

    await protocol.CPCCampaign.validatePlasmaContract(campaignAddress, protocol.plasmaAddress);

    await new Promise(resolve => setTimeout(resolve, 3000));

    const isPlasmaValid = await protocol.CPCCampaign.checkIsPlasmaContractValid(campaignAddress);

    expect(isPlasmaValid).to.be.eq(true);
  }).timeout(TIMEOUT_LENGTH);

  it('should set on plasma contract inventory amount from maintainer', async () => {
    const {protocol} = availableUsers[maintainerKey];
    const {campaignAddress, campaign} = storage;

    const amountOfTokensAvailable = await protocol.CPCCampaign.getInitialBountyAmount(campaign.campaignAddressPublic);

    const maxNumberOfConversionsCalculated = campaignParams.targetClicks
      || Math.floor(
        amountOfTokensAvailable /
        campaignParams.bountyPerConversionWei
      );

    await protocol.CPCCampaign.setTotalBountyPlasma(
      campaignAddress,
      protocol.Utils.toWei(amountOfTokensAvailable, 'ether'),
      maxNumberOfConversionsCalculated,
      protocol.plasmaAddress
    );
    await new Promise(resolve => setTimeout(resolve, 4000));
    const maxNumberOfConversions = await protocol.CPCCampaign.getMaxNumberOfConversions(campaignAddress);

    expect(maxNumberOfConversions).to.be.equal(maxNumberOfConversionsCalculated);
  }).timeout(TIMEOUT_LENGTH);

  it('should set that public contract is valid from maintainer', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    await protocol.Utils.getTransactionReceiptMined(
      await protocol.CPCCampaign.validatePublicContract(campaignAddress, address)
    );
    const isPublicValid = await protocol.CPCCampaign.checkIsPublicContractValid(campaignAddress);

    expect(isPublicValid).to.be.eq(true);
  }).timeout(TIMEOUT_LENGTH);

  it('should get campaign from IPFS', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const campaignMeta = await protocol.CPCCampaign.getPublicMeta(campaignAddress, protocol.plasmaAddress);
    expect(campaignMeta.meta.url).to.be.equal(campaignParams.url);
  }).timeout(TIMEOUT_LENGTH);

  it('should get public link key of contractor', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const pkl = await protocol.CPCCampaign.getPublicLinkKey(campaignAddress, protocol.plasmaAddress);
    expect(pkl.length).to.be.greaterThan(0);
  }).timeout(TIMEOUT_LENGTH);
}
