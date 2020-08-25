import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import cpcOnly from "../checks/cpcOnly";

export default function merkleCopyTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  cpcOnly(storage.campaignType);

  it(`should copy the merkle root from plasma to the mainchain by maintainer`, async () => {
    // const {web3: {address}} = availableUsers[userKey];
    // const {protocol} = availableUsers[userKey];
    // const {campaignAddress} = storage;
    //
    // await new Promise(resolve => setTimeout(resolve, 1000));
    // let txHash = await protocol.CPCCampaign.lockContractAndPushTotalRewards(campaignAddress, address);
    //
    // await protocol.Utils.getTransactionReceiptMined(
    //   txHash
    // );
    // console.log(txHash);
    //
    // await new Promise(resolve => setTimeout(resolve, 4000));
    // const isLocked = await protocol.CPCCampaign.isContractLocked(campaignAddress, "PUBLIC");
    // expect(isLocked).to.be.equal(true);
  }).timeout(60000);
}
