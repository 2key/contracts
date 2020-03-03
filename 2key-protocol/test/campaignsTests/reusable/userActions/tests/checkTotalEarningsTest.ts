import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";

export default function checkTotalEarningsTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  it('should get moderator total earnings in campaign', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const totalEarnings = await protocol[campaignContract].getModeratorTotalEarnings(campaignAddress, address);
    console.log('Moderator total earnings: ' + totalEarnings);
  }).timeout(60000);
}
