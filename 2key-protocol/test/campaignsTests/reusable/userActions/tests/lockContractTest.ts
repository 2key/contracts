import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import cpcOnly from "../checks/cpcOnly";
import {promisify} from "../../../../../src/utils/promisify";

export default function lockContractTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  cpcOnly(storage.campaignType);

  it(`should lock contract (end campaign) from maintainer`, async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;
    // @ts-ignore
    const s = await protocol.CPCCampaign._getPlasmaCampaignInstance(campaignAddress);

    await protocol.CPCCampaign.lockContractFromMaintainer(campaignAddress, protocol.plasmaAddress);
    await new Promise(resolve => setTimeout(resolve, 2000));
    // TODO: replace with protocol getter
    const merkleRoot = Number(await promisify(s.merkleRoot, []));

    expect(merkleRoot).to.be.gt(0);
  }).timeout(60000);
}
