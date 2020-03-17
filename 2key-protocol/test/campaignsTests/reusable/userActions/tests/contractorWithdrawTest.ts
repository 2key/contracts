import {expect} from "chai";
import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";

// TODO: add balance change assertion using data from console.log
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

    const balance2keyBefore = Number.parseFloat((await protocol.getBalance(address)).balance["2KEY"].toString());

    const contractorBalanceBefore = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].contractorWithdraw(campaignAddress, address)
    );

    const userDeptsAfter = await protocol.TwoKeyFeeManager.getDebtForUser(protocol.plasmaAddress);
    const balance2keyAfter = Number.parseFloat((await protocol.getBalance(address)).balance["2KEY"].toString());
    const contractorBalance = await protocol[campaignContract].getContractorBalance(campaignAddress, address);

    console.log({contractorBalanceBefore, userDeptsBefore, balance2keyBefore, userDeptsAfter, balance2keyAfter});

    expect(contractorBalance.available).to.be.eq(0);
  }).timeout(60000);
}
