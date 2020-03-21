import functionParamsInterface from "../typings/functionParamsInterface";
import availableUsers from "../../../../constants/availableUsers";
import {expect} from "chai";
import kycRequired from "../checks/kycRequired";

export default function checkPendingConvertersTest(
  {
    storage,
    userKey,
    campaignData,
    campaignContract,
  }: functionParamsInterface,
) {
  kycRequired(campaignData.isKYCRequired);

  it('should check pending converters', async () => {
    const {protocol, web3: {address}} = availableUsers[userKey];
    const {campaignAddress} = storage;

    const addresses = await protocol[campaignContract].getAllPendingConverters(campaignAddress, address);

    const pendingUsersAddresses = storage.pendingUsers
      .map(({id}) => availableUsers[id].web3.address);

    expect(addresses.length).to.be.eq(pendingUsersAddresses.length);
    expect(addresses).to.have.members(pendingUsersAddresses);
  }).timeout(60000);
}
