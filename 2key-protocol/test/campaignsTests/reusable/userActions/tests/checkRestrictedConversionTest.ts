import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import kycRequired from "../checks/kycRequired";

export default function checkRestrictedConversionTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    contribution,
    campaignContract,
    campaignData,
  }: functionParamsInterface,
) {
  kycRequired(campaignData.isKYCRequired);

  it(`should produce an error on conversion from rejected user (${secondaryUserKey})`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const {refUserKey} = storage.getUser(userKey);
    const {link: refLink} = storage.getUser(refUserKey);
    let error = false;

    try {
      await protocol.Utils.getTransactionReceiptMined(
        await protocol[campaignContract].joinAndConvert(
          campaignAddress,
          protocol.Utils.toWei(contribution, 'ether'),
          refLink.link,
          address,
          {fSecret: refLink.fSecret},
        )
      );

    } catch {
      error = true;
    }

    expect(error).to.be.eq(true);
  }).timeout(60000);
}
