import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../../helpers/numberHelpers";

export default function checkWithdrawableBalanceTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    campaignContract,
  }: functionParamsInterface,
) {
  it('should check referrer balance after hedging is done so hedge-rate exists', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {web3: {address: secondaryAddress}} = availableUsers[secondaryUserKey];
    const {campaignAddress} = storage;
    const user = storage.getUser(secondaryUserKey);

    const withdrawable = await protocol[campaignContract].getAmountReferrerCanWithdraw(
      campaignAddress, secondaryAddress, address,
    );

    expectEqualNumbers(withdrawable.balance2key, user.referrerReward);
  }).timeout(60000);
}
