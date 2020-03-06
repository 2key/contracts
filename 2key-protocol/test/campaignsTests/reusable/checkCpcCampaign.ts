import {ICreateCPC} from "../../../src/cpc/interfaces";
import availableUsers from "../../constants/availableUsers";
import {expect} from "chai";

const TIMEOUT_LENGTH = 60000;

export default function checkCpcCampaign(campaignParams: ICreateCPC, storage, maintainerKey: string) {
  const userKey = storage.contractorKey;

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

  it('should buy referral rewards on public contract by sending ether', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const inventoryBefore = await protocol.CPCCampaign.getTokensAvailableInInventory(campaignAddress);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol.CPCCampaign
        .buyTokensForReferralRewards(
          campaignAddress,
          // @ts-ignore
          protocol.Utils.toWei(campaignParams.etherForRewards, 'ether'),
          address
        )
    );

    const inventoryAfter = await protocol.CPCCampaign.getTokensAvailableInInventory(campaignAddress);
    const boughtRate = await protocol.CPCCampaign.getBought2keyRate(campaignAddress);
    const eth2usd = await protocol.TwoKeyExchangeContract.getBaseToTargetRate("USD");

    expect((inventoryAfter - inventoryBefore) * boughtRate)
      // @ts-ignore
      .to.be.equal(campaignParams.etherForRewards * eth2usd);

  }).timeout(TIMEOUT_LENGTH);


  it('should set that plasma contract is valid from maintainer', async () => {
    const {protocol} = availableUsers[maintainerKey];
    const {campaignAddress} = storage;

    const isValidatedBefore = await protocol.CPCCampaign.checkIsPlasmaContractValid(campaignAddress);

    await protocol.CPCCampaign.validatePlasmaContract(campaignAddress, protocol.plasmaAddress);

    const isValidatedAfter = await protocol.CPCCampaign.checkIsPlasmaContractValid(campaignAddress);

    expect(isValidatedBefore).to.be.eq(false);
    expect(isValidatedAfter).to.be.eq(true);
  }).timeout(TIMEOUT_LENGTH);

  it('should set on plasma contract inventory amount from maintainer', async () => {
    const {protocol} = availableUsers[maintainerKey];
    const {campaignAddress} = storage;

    const amountOfTokensAvailable = await protocol.CPCCampaign.getTokensAvailableInInventory(campaignAddress);

    const maxNumberOfConversionsCalculated = Math.floor(
      amountOfTokensAvailable /
      campaignParams.bountyPerConversionWei
    );

    await protocol.CPCCampaign.setTotalBountyPlasma(
      campaignAddress,
      protocol.Utils.toWei(amountOfTokensAvailable, 'ether'),
      maxNumberOfConversionsCalculated,
      protocol.plasmaAddress
    );
    const  maxNumberOfConversions = await protocol.CPCCampaign.getMaxNumberOfConversions(campaignAddress);

    expect(maxNumberOfConversions).to.be.equal(maxNumberOfConversionsCalculated);
  }).timeout(TIMEOUT_LENGTH);

  it('should set that public contract is valid from maintainer', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    await protocol.Utils.getTransactionReceiptMined(
      await protocol.CPCCampaign.validatePublicContract(campaignAddress, address)
    );
  }).timeout(TIMEOUT_LENGTH);

  it('should get campaign from IPFS', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const campaignMeta = await protocol.CPCCampaign.getPublicMeta(campaignAddress,protocol.plasmaAddress);
    expect(campaignMeta.meta.url).to.be.equal(campaignParams.url);
  }).timeout(TIMEOUT_LENGTH);

  it('should get public link key of contractor', async() => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const pkl = await protocol.CPCCampaign.getPublicLinkKey(campaignAddress, protocol.plasmaAddress);
    expect(pkl.length).to.be.greaterThan(0);
  }).timeout(TIMEOUT_LENGTH);
}
