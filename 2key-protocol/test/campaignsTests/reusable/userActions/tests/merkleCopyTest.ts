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
    const {web3: {address}} = availableUsers[userKey];
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const root = await protocol.CPCCampaign.getMerkleRootFromPlasma(campaignAddress);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol.CPCCampaign.setMerkleRootOnMainchain(campaignAddress,root, address)
    );

    await new Promise(resolve => setTimeout(resolve, 4000));

    const rootOnPublic = await protocol.CPCCampaign.getMerkleRootFromPublic(campaignAddress);
    expect(root).to.be.equal(rootOnPublic);
  }).timeout(60000);
}
