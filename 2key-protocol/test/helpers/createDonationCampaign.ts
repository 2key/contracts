import availableUsers, {userIds} from "../constants/availableUsers";
import {ICreateCampaign} from "../../src/donation/interfaces";

export default async function createDonationCampaign(campaignData: ICreateCampaign, storage) {
  const {web3: {address}, protocol} = availableUsers[storage.contractorKey];
  const storageUser = storage.getUser(storage.contractorKey);

  const campaign = await protocol.DonationCampaign.create(
    campaignData,
    campaignData,
    {},
    address,
    {
      gasPrice: 150000000000,
      interval: 500,
      timeout: 600000,
    });
  const {
    campaignPublicLinkKey, fSecret,
  } = campaign;

  storage.campaign = campaign;
  storageUser.link =  {link: campaignPublicLinkKey, fSecret: fSecret};
}
