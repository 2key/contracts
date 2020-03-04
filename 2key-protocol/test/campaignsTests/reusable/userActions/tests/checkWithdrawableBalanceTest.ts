import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expectEqualNumbers} from "../../../helpers/numberHelpers";

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
    const {address: secondaryAddress} = availableUsers[secondaryUserKey];
    const {campaignAddress} = storage;

    const withdrawable = await protocol[campaignContract].getAmountReferrerCanWithdraw(
      campaignAddress, secondaryAddress, address,
    );
    /*
    executed conversion: maxReferralReward2key = 1666.6666666666667

    {
     balance2key: 1666.6666666666667,
     balanceDAI: 909.0909090517757
    }
     */
    // todo: incorrect should use sum of all referrer rewards for this user
    expectEqualNumbers(withdrawable.balance2key, storage.totalBounty);
  }).timeout(60000);
}
