import availableUsers, {userIds} from "../../constants/availableUsers";

export default async function createAcquisitionCampaign(campaignData, storage) {
  const {web3: {address}, protocol} = availableUsers[storage.contractorKey];
  const storageUser = storage.getUser(storage.contractorKey);

  const campaign = await protocol.AcquisitionCampaign.create(
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
