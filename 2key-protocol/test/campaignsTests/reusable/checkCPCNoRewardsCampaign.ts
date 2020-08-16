import availableUsers, {userIds} from "../../constants/availableUsers";
import {expect} from "chai";
import {expectEqualNumbers} from "../../helpers/numberHelpers";
import {ICreateCPCNoRewards} from "../../../src/cpcNoRewards/interfaces";

const TIMEOUT_LENGTH = 60000;

export default function checkCpcNoRewardsCampaign(campaignParams: ICreateCPCNoRewards, storage, maintainerKey: string) {
    const userKey = storage.contractorKey;

    it('should get contractor plasma and public address', async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];
        const {campaignAddress} = storage;

        const addresses = await protocol.CPCCampaignNoRewards.getContractorAddresses(campaignAddress);
        expect(addresses.contractorPlasma).to.be.equal(protocol.plasmaAddress);
    }).timeout(TIMEOUT_LENGTH);

    it('should check if address is contractor', async () => {
        const {protocol, web3: {address}} = availableUsers[userKey];

        const isContractor = await protocol.CPCCampaignNoRewards.isAddressContractor(storage.campaign.campaignAddress, address);
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

        await protocol.CPCCampaign.setTotalBountyPlasma(
            campaignAddress,
            protocol.Utils.toWei(amountOfTokensAvailable, 'ether'),
            protocol.plasmaAddress
        );

        await new Promise(resolve => setTimeout(resolve, 4000));

        const bounty = await protocol.CPCCampaign.getTotalBountyAndBountyPerConversion(campaignAddress);
        expect(bounty.totalBounty).to.be.equal(amountOfTokensAvailable);
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
