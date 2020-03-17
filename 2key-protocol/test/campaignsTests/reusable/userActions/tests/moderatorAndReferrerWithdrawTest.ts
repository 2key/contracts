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
    const signature = await protocol.PlasmaEvents.signReferrerToGetRewards();

    const {balanceAvailable: availableBefore} = await protocol[campaignContract]
      .getReferrerBalanceAndTotalEarningsAndNumberOfConversions(campaignAddress, signature);
    const balance2keyBefore = Number.parseFloat((await protocol.getBalance(address)).balance["2KEY"].toString());

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].moderatorAndReferrerWithdraw(
        campaignAddress,
        false,
        address,
      )
    );
    const balance2keyAfter = Number.parseFloat((await protocol.getBalance(address)).balance["2KEY"].toString());

    const {balanceAvailable} = await protocol[campaignContract]
      .getReferrerBalanceAndTotalEarningsAndNumberOfConversions(campaignAddress, signature);

    expectEqualNumbers(balanceAvailable, 0);
    expectEqualNumbers(
      availableBefore,
      Number.parseFloat(
        protocol.Utils.fromWei(balance2keyAfter - balance2keyBefore, 'ether').toString()
      )
    );
  }).timeout(60000);
}
