import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";

export default function checkModeratorEarningsTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  // todo: conversionAmount(ETH) * 0.02 * usdRate * rateUsd2key
  it('should check moderator earnings', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    let moderatorTotalEarnings = await protocol[campaignContract].getModeratorTotalEarnings(campaignAddress, address);
    console.log('Moderator total earnings in 2key-tokens are: ' + moderatorTotalEarnings);
    // Moderator total earnings in 2key-tokens are: 163.33333333333334
  }).timeout(60000);
}
