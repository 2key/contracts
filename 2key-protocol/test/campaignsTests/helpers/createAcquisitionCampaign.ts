import availableUsers, {userIds} from "../../constants/availableUsers";
import {availableStorageUserFields} from "../../constants/storageConstants";
import {campaignTypes} from "../../constants/smallConstants";

export default async function createAcquisitionCampaign(campaignData, storage) {
  const {web3: {address}, protocol} = availableUsers[storage.contractorKey];

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

  storage.setUserData(
    storage.contractorKey,
    availableStorageUserFields.link,
    {link: campaignPublicLinkKey, fSecret: fSecret},
  );
}
