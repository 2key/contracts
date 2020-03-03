import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";

export default function moderatorAndReferrerWithdrawTest(
  {
    storage,
    userKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  // todo: check user referrer balance, what balance should be checked???
  it('should referrer withdraw his balances in 2key-tokens', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const {balance: before} = await protocol.getBalance(address, campaignData.assetContractERC20);
    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].moderatorAndReferrerWithdraw(
        campaignAddress,
        false,
        address,
      )
    );
    const {balance: after} = await protocol.getBalance(address, campaignData.assetContractERC20);
    console.log(before.ETH.toString(), before['2KEY'].toString());
    console.log(after.ETH.toString(), after['2KEY'].toString());

  }).timeout(60000);
}
