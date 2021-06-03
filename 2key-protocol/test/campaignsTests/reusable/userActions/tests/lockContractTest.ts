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

  it(`should try to lock contract (end campaign) from maintainer, and expect error (24hrs req)`, async () => {
    const {protocol} = availableUsers[userKey];
    const {campaignAddress} = storage;

    let error = false;

    try {
      await protocol.CPCCampaign.lockContractFromMaintainer(
          campaignAddress,
          protocol.plasmaAddress
      ).catch(e => console.log('Eroror herer'))
    } catch (e) {
      console.log('EORORORORO')
      error = true;
    }
    console.log('THIS WORKS')


    const isContractLocked = await protocol.CPCCampaign.isContractLocked(campaignAddress,"PLASMA");

    console.log(error)
    console.log(isContractLocked)
    expect(error).to.be.eq(true);
    expect(isContractLocked).to.be.eq(false);
  }).timeout(60000);
}
