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

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].contractorWithdraw(campaignAddress, address)
    );

    const contractorBalance = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

    expect(contractorBalance.available).to.be.eq(0);
  }).timeout(60000);
}
