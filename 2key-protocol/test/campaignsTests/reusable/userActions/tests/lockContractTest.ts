import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import cpcOnly from "../checks/cpcOnly";

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
    await protocol.CPCCampaign.lockContractFromMaintainer(campaignAddress, protocol.plasmaAddress);
    await new Promise(resolve => setTimeout(resolve, 2000));
    // todo: add assertion
  }).timeout(60000);
}
