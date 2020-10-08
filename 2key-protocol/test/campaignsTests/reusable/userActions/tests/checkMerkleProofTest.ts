import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import cpcOnly from "../checks/cpcOnly";

export default function checkMerkleProofTest(
  {
    storage,
    userKey,
  }: functionParamsInterface,
) {
  cpcOnly(storage.campaignType);

  it(`should get merkle proof from roots and on the main chain as an ${userKey}`, async () => {
    // const {protocol} = availableUsers[userKey];
    // const {campaignAddress} = storage;
    //
    // const proofs = await protocol.CPCCampaign.getMerkleProofFromRoots(campaignAddress, protocol.plasmaAddress);
    // const isProofValid = await protocol.CPCCampaign.checkMerkleProofAsInfluencer(campaignAddress, protocol.plasmaAddress);
    //
    // expect(proofs.length).to.be.greaterThan(0);
    // expect(isProofValid).to.be.equal(true);
  }).timeout(60000);
}
