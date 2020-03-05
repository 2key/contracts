import '../../constants/polifils';
import {expect} from 'chai';
import availableUsers from "../../constants/availableUsers";
import {IPrivateMetaInformation} from "../../../src/acquisition/interfaces";
import TestStorage from "../../helperClasses/TestStorage";
import {ICreateCampaign} from "../../../src/donation/interfaces";
import {campaignTypes} from "../../constants/smallConstants";


export default function checkDonationCampaign(campaignParams: ICreateCampaign, storage: TestStorage) {
  const userKey = storage.contractorKey;

  it('should check campaign type by address', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const campaignType = await protocol.TwoKeyFactory.getCampaignTypeByAddress(campaignAddress);

    expect(campaignType).to.be.equal(campaignTypes.donation);
  }).timeout(60000);

  it('check is campaign validated', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const isValidated = await protocol.CampaignValidator.isCampaignValidated(campaignAddress);

    expect(isValidated).to.be.equal(true);
  }).timeout(60000);

  it('validate non singleton hash', async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const nonSingletonHash = await protocol.CampaignValidator.getCampaignNonSingletonsHash(
      campaignAddress
    );
    expect(nonSingletonHash).to.be.equal(protocol.DonationCampaign.getNonSingletonsHash());
  });

  it('check contractor user', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const isContractor: boolean = await protocol.DonationCampaign.isAddressContractor(campaignAddress, address);

    expect(isContractor).to.be.equal(true);
  });

  it('should check incentive model', async() => {
    const {protocol, } = availableUsers[userKey];
    const {campaignAddress} = storage;

    const model = await protocol.DonationCampaign.getIncentiveModel(campaignAddress);
    expect(model).to.be.equal(campaignParams.incentiveModel);
  }).timeout(60000);

  it('should get campaign public meta from IPFS', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const campaignMeta = await protocol.AcquisitionCampaign.getPublicMeta(campaignAddress, from);

    expect(campaignMeta.meta.currency).to.be.equal(campaignParams.currency);
  }).timeout(120000);

  it('should get user public link', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;

      const publicLink = await protocol.DonationCampaign.getPublicLinkKey(campaignAddress, from);

      expect(parseInt(publicLink, 16)).to.be.greaterThan(0);
  }).timeout(10000);

  it('should get and decrypt ipfs hash', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const {link} = storage.getUser(userKey);

    let data: IPrivateMetaInformation = await protocol.DonationCampaign.getPrivateMetaHash(
      campaignAddress, from);

    expect(data.campaignPublicLinkKey).to.be.equal(link.link);
  }).timeout(120000);

  // todo: assert
  /*
  { ethWeiAvailableToHedge: 0,
  daiWeiAvailableToWithdraw: 0,
  daiWeiReceivedFromHedgingPerContract: 0,
  ethWeiHedgedPerContract: 0,
  sent2keyToContract: 0,
  ethReceivedFromContract: 0 }
   */
  // todo: add assert
  it('should check stats for the contract from upgradable exchange', async () => {
    const {protocol, web3: {address: from}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    let stats = await protocol.UpgradableExchange.getStatusForTheContract(campaignAddress, from);
    // console.log(stats);
  }).timeout(60000);
}
