import availableUsers, {userIds} from "../../constants/availableUsers";
import {ICreateCampaign} from "../../../src/donation/interfaces";
import {ICreateCPC} from "../../../src/cpc/interfaces";

export default async function createCpcCampaign(campaignData: ICreateCPC, storage) {
  const {web3: {address}, protocol} = availableUsers[storage.contractorKey];
  const storageUser = storage.getUser(storage.contractorKey);

  const campaignObject = {
    ...campaignData,
    bountyPerConversionWei: parseFloat(protocol.Utils.toWei(campaignData.bountyPerConversionWei,'ether').toString())
  };

  const campaign = await protocol.CPCCampaign.createCPCCampaign(
    campaignObject,
    campaignObject,
    {},
    protocol.plasmaAddress,
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
