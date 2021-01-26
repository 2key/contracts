import availableUsers from "../constants/availableUsers";
import { ICreateCPCNoRewards } from "../../src/cpcNoRewards/interfaces";

export default async function createCpcCampaign(campaignData: ICreateCPCNoRewards, storage) {
  const {web3: {address}, protocol} = availableUsers[storage.contractorKey];
  const storageUser = storage.getUser(storage.contractorKey);

  const campaignObject = {
    ...campaignData,
  };

  const campaign = await protocol.CPCCampaignNoRewards.createCPCCampaign(
    campaignObject,
    campaignObject,
    {},
    protocol.plasmaAddress,
    address,
    {
      gasPrice: 150000000000,
      interval: 500,
      timeout: 100000,
    });
  const {
    campaignPublicLinkKey, fSecret,
  } = campaign;

  storage.campaign = campaign;
  storageUser.link =  {link: campaignPublicLinkKey, fSecret: fSecret};
}
