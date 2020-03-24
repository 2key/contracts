import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";

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

    const eth2KeyRate = await protocol.UpgradableExchange.getEth2KeyAverageRatePerContract(campaignAddress, address);
    const signature = await protocol.PlasmaEvents.signReferrerToGetRewards();

    const userDeptsBefore = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);
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

    if (userDeptsBefore > 0) {
      const userDeptsAfter = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);
      expect(userDeptsAfter).to.be.lt(userDeptsBefore);
    }

    expectEqualNumbers(balanceAvailable, 0);
    expectEqualNumbers(
      availableBefore,
      Number.parseFloat(
        protocol.Utils.fromWei(balance2keyAfter - balance2keyBefore - userDeptsBefore * eth2KeyRate, 'ether').toString()
      )
    );
  }).timeout(60000);
}
