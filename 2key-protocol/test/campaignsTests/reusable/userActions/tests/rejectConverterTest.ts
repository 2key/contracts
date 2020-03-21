import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {userStatuses} from "../../../../constants/smallConstants";
import {expect} from "chai";
import kycRequired from "../checks/kycRequired";

export default function rejectConverterTest(
  {
    storage,
    userKey,
    campaignData,
    secondaryUserKey,
    campaignContract,
  }: functionParamsInterface,
) {
  kycRequired(campaignData.isKYCRequired);

  it(`should reject ${secondaryUserKey} converter`, async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {web3: {address: secAddress}} = availableUsers[secondaryUserKey];
    const {campaignAddress} = storage;
    const userForReject = storage.getUser(secondaryUserKey);

    await protocol.Utils.getTransactionReceiptMined(
      await protocol[campaignContract].rejectConverter(campaignAddress, secAddress, address)
    );

    // smart contracts doesn't change user status on reject
    userForReject.status = userStatuses.rejected;
    const rejected = await protocol[campaignContract].getAllRejectedConverters(campaignAddress, address);
    const pending = await protocol[campaignContract].getAllPendingConverters(campaignAddress, address);

    const pendingUsersAddresses = storage.pendingUsers
      .map(({id}) => availableUsers[id].web3.address);
    const rejectedUsersAddresses = storage.rejectedUsers
      .map(({id}) => availableUsers[id].web3.address);


    expect(rejected.length).to.be.eq(rejectedUsersAddresses.length);
    expect(rejected).to.have.members(rejectedUsersAddresses);
    expect(pending.length).to.be.eq(pendingUsersAddresses.length);
    expect(pending).to.have.members(pendingUsersAddresses);
  }).timeout(60000);

}
