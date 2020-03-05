import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";

export default function moderatorAndReferrerWithdrawTest(
  {
    storage,
    userKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  it('should referrer withdraw his balances in 2key-tokens', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].moderatorAndReferrerWithdraw(
        campaignAddress,
        false,
        address,
      )
    );
    const signature = await protocol.PlasmaEvents.signReferrerToGetRewards();
    const {balanceAvailable} = await protocol[campaignContract].getReferrerBalanceAndTotalEarningsAndNumberOfConversions(campaignAddress, signature);

    expectEqualNumbers(balanceAvailable, 0);
  }).timeout(60000);
}
