import availableUsers from "../../constants/availableUsers";

export default function createCampaign(campaignData, user) {
  const {web3: {address}, protocol} = user;

  return protocol.AcquisitionCampaign.create(
    campaignData,
    campaignData,
    {},
    address,
    {
      gasPrice: 150000000000,
      interval: 500,
      timeout: 600000,
    });
}
