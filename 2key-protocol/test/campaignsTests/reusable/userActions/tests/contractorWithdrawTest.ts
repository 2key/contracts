import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";


export default function contractorWithdrawTest(
  {
    storage,
    userKey,
    campaignContract,
  }: functionParamsInterface,
) {
  it('should contractor withdraw his earnings', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const userDeptsBefore = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].contractorWithdraw(campaignAddress, address)
    );

    const contractorBalance = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

    if (userDeptsBefore > 0) {
      const userDeptsAfter = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);
      expect(userDeptsAfter).to.be.lt(userDeptsBefore);
    }

    expect(contractorBalance.available).to.be.eq(0);
  }).timeout(60000);
}
