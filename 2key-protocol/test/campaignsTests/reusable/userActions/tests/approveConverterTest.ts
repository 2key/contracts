import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {userStatuses} from "../../../../constants/smallConstants";
import {expect} from "chai";
import kycRequired from "../checks/kycRequired";

export default function approveConverterTest(
  {
    storage,
    userKey,
    secondaryUserKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  kycRequired(campaignData.isKYCRequired);

  it(`should approve ${secondaryUserKey} converter`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;
    const {address: secAddress} = availableUsers[secondaryUserKey];
    const userForApprove = storage.getUser(secondaryUserKey);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].approveConverter(campaignAddress, secAddress, address),
    );

    userForApprove.status = userStatuses.approved;

    const approved = await protocol[campaignContract].getApprovedConverters(campaignAddress, address);
    const pending = await protocol[campaignContract].getAllPendingConverters(campaignAddress, address);

    const pendingUsersAddresses = storage.pendingUsers
      .map(({id}) => availableUsers[id].web3.address);
    const approvedUsersAddresses = storage.approvedUsers
      .map(({id}) => availableUsers[id].web3.address);

    expect(approved.length).to.be.eq(approvedUsersAddresses.length);
    expect(approved).to.have.members(approvedUsersAddresses);
    expect(pending.length).to.be.eq(pendingUsersAddresses.length);
    expect(pending).to.have.members(pendingUsersAddresses);
  }).timeout(60000);
}
